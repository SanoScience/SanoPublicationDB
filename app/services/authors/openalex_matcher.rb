require "jaro_winkler"

module Authors
  class OpenalexMatcher
    MATCH_THRESHOLD = 0.93

    def self.match(openalex_authors)
      new.match(openalex_authors)
    end

    def initialize
      @existing_people = Author.author_type_filter(:person)
                               .select(:id, :first_name, :last_name)
                               .to_a
      @existing_collectives = Author.author_type_filter(:collective)
                                    .select(:id, :collective_name)
                                    .to_a
    end

    def match(openalex_authors)
      openalex_authors.filter_map do |author_data|
        display_name = author_data["display_name"]
        
        parsed_name = simple_parse(display_name)
        next if parsed_name.nil?

        if parsed_name[:author_type] == "collective"
          best_match = find_best_collective_match(parsed_name[:collective_name])

          if best_match
            { 
              match_type: "existing", 
              id: best_match.id, 
              display_name: best_match.collective_name 
            }
          else
            { 
              match_type: "new", 
              author_type: "collective", 
              collective_name: parsed_name[:collective_name] 
            }
          end
        else
          best_match = find_best_person_match(parsed_name[:first_name], parsed_name[:last_name])

          if best_match
            { 
              match_type: "existing", 
              id: best_match.id, 
              display_name: "#{best_match.first_name} #{best_match.last_name}" 
            }
          else
            { 
              match_type: "new", 
              author_type: "person", 
              title: parsed_name[:title],
              first_name: parsed_name[:first_name], 
              last_name: parsed_name[:last_name] 
            }
          end
        end
      end
    end

    private

    def simple_parse(display_name)
      name = display_name.to_s.gsub(/\s+/, " ").strip
      return nil if fuzzy_normalize(name).blank?

      if Authors::NameUtils.looks_like_collective?(name)
        return { author_type: "collective", collective_name: name }
      end

      title, body = Authors::NameUtils.extract_title_prefix(name)
      
      first_name, last_name = Authors::NameUtils.extract_first_and_last_name(body)

      { 
        author_type: "person", 
        title: title.presence, 
        first_name: first_name, 
        last_name: last_name 
      }
    end

    def find_best_person_match(first_name, last_name)
      return nil if last_name.blank?

      norm_first = fuzzy_normalize(first_name)
      norm_last = fuzzy_normalize(last_name)
      best_score = 0.0
      best_author = nil

      @existing_people.each do |author|
        db_first = fuzzy_normalize(author.first_name)
        db_last = fuzzy_normalize(author.last_name)

        last_score = JaroWinkler.similarity(norm_last, db_last)

        if last_score > MATCH_THRESHOLD
          first_score = JaroWinkler.similarity(norm_first, db_first)

          if norm_first.length == 1 || db_first.length == 1
            first_score = 1.0 if norm_first[0] == db_first[0]
          end

          avg_score = (first_score + last_score) / 2.0

          if avg_score > best_score && avg_score >= MATCH_THRESHOLD
            best_score = avg_score
            best_author = author
          end
        end
      end

      best_author
    end

    def find_best_collective_match(collective_name)
      norm_target = fuzzy_normalize(collective_name)
      best_score = 0.0
      best_author = nil

      @existing_collectives.each do |author|
        db_name = fuzzy_normalize(author.collective_name)
        score = JaroWinkler.similarity(norm_target, db_name)

        if score > best_score && score >= MATCH_THRESHOLD
          best_score = score
          best_author = author
        end
      end

      best_author
    end

    def fuzzy_normalize(value)
      I18n.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]+/, "")
    end
  end
end
