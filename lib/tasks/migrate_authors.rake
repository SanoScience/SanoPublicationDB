require "csv"
require "set"
require "fileutils"

namespace :data do
  desc "Migrate Publication.author_list into authors and publication_authorships"
  task migrate_authors: :environment do
    module AuthorMigration
      module_function

      NAME_PARTICLES = %w[
        al ap ben bin da dal de del della der di dos du el la le van von ten ter den
      ].freeze

      TITLE_TOKENS = %w[
        prof professor dr md phd msc bsc mph dabr dabnm mr mrs ms
      ].freeze

      COLLECTIVE_KEYWORDS = %w[
        group team consortium initiative network collaboration committee society
        biobank investigators investigator study trial board association program programme
        institute center centre unit foundation panel registry working mission laboratory
      ].freeze

      TRUNCATION_PATTERNS = [
        /et\s+al\.?(?:\s*\([^)]*\))?/i,
        /\(\s*many others\s*\)/i,
        /\(\s*\.\.\.\s*\)/i,
        /\.{3,}/i,
        /additional authors not shown/i,
        /many others/i
      ].freeze

      def normalize(raw)
        s = raw.to_s.unicode_normalize(:nfkc)
        s = s.gsub("\u00A0", " ")
        s = s.gsub(/[[:space:]]+/, " ")
        s = s.gsub(/\s+,/, ",")
        s = s.gsub(/,\s*,+/, ",")
        s = s.strip

        s = s.gsub(/\s*&\s*/i, ", ")
        s = s.gsub(/\s+and\s+/i, ", ")
        s = s.gsub(/,\s*and\s+/i, ", ")
        s = s.gsub(/\s*;\s*/, ", ")
        s = s.gsub(/\s*,\s*/, ", ")

        s.gsub(/[[:space:]]+/, " ").strip
      end

      def normalize_spacing(value)
        value.to_s.gsub(/[[:space:]]+/, " ").strip
      end

      def canonical(value)
        s = value.to_s.unicode_normalize(:nfkc)
        s = s.gsub(/[\u200B\u200C\u200D\uFEFF]/, "")
        s = s.tr("’`´", "'")
        s = s.tr("‐-‒–—−", "-")
        s = normalize_spacing(s)
        s = I18n.transliterate(s)
        s.downcase
      end

      def clean_word(word)
        word.to_s.strip.gsub(/\A[[:punct:]]+|[[:punct:]]+\z/, "")
      end

      def words(token)
        token.to_s.split(/\s+/).map(&:strip).reject(&:blank?)
      end

      def title_word?(word)
        TITLE_TOKENS.include?(clean_word(word).downcase)
      end

      def particle?(word)
        NAME_PARTICLES.include?(clean_word(word).downcase)
      end

      def collective_keyword?(token)
        downcased = canonical(token)
        COLLECTIVE_KEYWORDS.any? { |kw| downcased.match?(/\b#{Regexp.escape(kw)}\b/) }
      end

      def normalize_collective_tail(token)
        t = normalize_spacing(token)

        return "..." if t.match?(/\Aet\s+al\.?\z/i)
        return "..." if t.match?(/\Aet\s+al\.?\s+\(\s*\d+\s+additional authors not shown\s*\)\z/i)
        return "..." if t.match?(/\Aet\s+al\.?\s+\(\s*additional authors not shown\s*\)\z/i)
        return "..." if t.match?(/\A\(?\s*many others\s*\)?\z/i)
        return "..." if t.match?(/\A\(?\s*additional authors not shown\s*\)?\z/i)
        return "..." if t.match?(/\A\(?\s*\d+\s+additional authors not shown\s*\)?\z/i)
        return "..." if t.match?(/\A(?:\(\s*\.\.\.\s*\)|\.{3,})\z/i)

        t
      end

      def extract_truncation_collectives(author_list)
        s = author_list.dup
        collectives = []

        loop do
          earliest = nil

          TRUNCATION_PATTERNS.each do |pattern|
            match = s.match(pattern)
            next unless match

            if earliest.nil? || match.begin(0) < earliest.begin(0)
              earliest = match
            end
          end

          break unless earliest

          matched = normalize_spacing(earliest[0])
          before = normalize_spacing(s[0...earliest.begin(0)])
          after  = normalize_spacing(s[earliest.end(0)..])

          if matched.match?(/et\s+al/i) && after.present?
            if after.match?(/\A\(\s*\d+\s+additional authors not shown\s*\)/i)
              extra = after.match(/\A(\(\s*\d+\s+additional authors not shown\s*\))/i)[1]
              matched = "#{matched} #{extra}"
              after = normalize_spacing(after.sub(/\A\(\s*\d+\s+additional authors not shown\s*\)/i, ""))
            elsif after.match?(/\A\(\s*additional authors not shown\s*\)/i)
              extra = after.match(/\A(\(\s*additional authors not shown\s*\))/i)[1]
              matched = "#{matched} #{extra}"
              after = normalize_spacing(after.sub(/\A\(\s*additional authors not shown\s*\)/i, ""))
            end
          end

          collectives << normalize_collective_tail(matched)
          s = [ before, after ].reject(&:blank?).join(", ")
          s = normalize(s)
        end

        [ normalize(s), collectives.reject(&:blank?) ]
      end

      def compact_initial_surname?(token)
        t = normalize_spacing(token)
        return false if t.include?(",")

        t.match?(/\A[\p{L}]{1,3}\.[\p{L}\-'.]+\z/u)
      end

      def initial_surname_token?(token)
        t = normalize_spacing(token)
        return false if t.include?(",")

        t.match?(/\A(?:[\p{L}]{1,3}\.?)(?:\s+(?:[\p{L}]{1,3}\.?))*\s+[\p{L}\-'.]+(?:\s+[\p{L}\-'.]+)*\z/u)
      end

      def full_name_token?(token)
        t = normalize_spacing(token)
        return false if t.include?(",")

        _title, body = extract_title_prefix(t)
        parts = words(body)
        return false if parts.length < 2
        return false if compact_initial_surname?(t)
        return false if initial_surname_token?(t)

        true
      end

      def one_word_fragment?(token)
        words(token).length == 1
      end

      def looks_like_collective?(token)
        t = normalize_spacing(token)
        truncation_collective_token?(t) || collective_keyword?(t)
      end

      def truncation_collective_token?(token)
        t = normalize_spacing(token)

        t.match?(/\Aet\s+al/i) ||
          t.match?(/\Amany others\z/i) ||
          t.match?(/\Aadditional authors not shown\z/i) ||
          t.match?(/\A\.\.\.\z/) ||
          t.match?(/\Aet\s+al\.\s+\(\s*\d+\s+additional authors not shown\s*\)\z/i)
      end

      def suspicious_token?(token)
        return true if token.blank?
        return false if truncation_collective_token?(token)
        return false if looks_like_collective?(token)

        token.match?(/[()]/)
      end

      def split_raw_parts(author_list)
        author_list.split(",").map { |part| normalize_spacing(part) }.reject(&:blank?)
      end

      def build_candidate_tokens(author_list)
        parts = split_raw_parts(author_list)
        tokens = []
        i = 0

        while i < parts.length
          current = parts[i]
          nxt = parts[i + 1]

          if truncation_collective_token?(current) || looks_like_collective?(current)
            tokens << normalize_collective_tail(current)
            i += 1
            next
          end

          if compact_initial_surname?(current) || initial_surname_token?(current) || full_name_token?(current)
            tokens << current
            i += 1
            next
          end

          if one_word_fragment?(current)
            if nxt.blank?
              return [ :review, { reason: "dangling_single_word_fragment", parsed_tokens: tokens + [ current ] } ]
            end

            merged = "#{current}, #{nxt}"
            tokens << merged
            i += 2
            next
          end

          tokens << current
          i += 1
        end

        [ :ok, tokens ]
      end

      def extract_title_prefix(token)
        parts = words(token)
        title_parts = []

        while parts.any? && title_word?(parts.first)
          title_parts << parts.shift
        end

        [ normalize_spacing(title_parts.join(" ")), normalize_spacing(parts.join(" ")) ]
      end

      def last_name_start_index(parts)
        idx = parts.length - 1
        while idx > 0 && particle?(parts[idx - 1])
          idx -= 1
        end
        idx
      end

      def initials_only?(name)
        name.to_s.strip.match?(/\A(?:[\p{L}]{1,3}\.?)(?:\s+[\p{L}]{1,3}\.?)*\z/u)
      end

      def initial_of(name)
        clean_word(name.to_s).slice(0)&.downcase
      end

      def parse_compact_initial_surname(token)
        t = normalize_spacing(token)

        match = t.match(/\A(?<initials>[\p{L}]{1,3})\.(?<surname>[\p{L}\-'.]+)\z/u)
        return [ :review, { reason: "bad_compact_initial_token", raw: token } ] unless match

        initials = "#{match[:initials]}."
        surname = match[:surname]

        [ :person, {
          first_name: initials,
          last_name: surname,
          title: nil,
          raw: token
        } ]
      end

      def parse_initial_surname(token)
        t = normalize_spacing(token)
        parts = words(t)

        return [ :review, { reason: "bad_initial_surname_token", raw: token } ] if parts.length < 2

        first_name = parts[0...-1].join(" ")
        last_name  = parts[-1]

        return [ :review, { reason: "bad_initial_surname_token", raw: token } ] if first_name.blank? || last_name.blank?

        [ :person, {
          first_name: first_name,
          last_name: last_name,
          title: nil,
          raw: token
        } ]
      end

      def parse_inverted_person(token)
        left, right = token.split(",", 2).map { |x| normalize_spacing(x) }
        return [ :review, { reason: "bad_inverted_token", raw: token } ] if left.blank? || right.blank?

        title, given_part = extract_title_prefix(right)
        given_words = words(given_part)
        surname_words = words(left)

        return [ :review, { reason: "missing_name_part", raw: token } ] if given_words.empty? || surname_words.empty?

        if given_words.length >= 2 && particle?(given_words.last)
          surname_words.unshift(given_words.pop)
        end

        first_name = normalize_spacing(given_words.join(" "))
        last_name  = normalize_spacing(surname_words.join(" "))

        return [ :review, { reason: "missing_name_part", raw: token } ] if first_name.blank? || last_name.blank?

        [ :person, {
          first_name: first_name,
          last_name: last_name,
          title: title.presence,
          raw: token
        } ]
      end

      def parse_normal_person(token)
        title, body = extract_title_prefix(token)
        parts = words(body)

        return [ :review, { reason: "too_few_parts", raw: token } ] if parts.length < 2

        split_index = last_name_start_index(parts)
        return [ :review, { reason: "cannot_find_last_name", raw: token } ] if split_index <= 0

        first_name = normalize_spacing(parts[0...split_index].join(" "))
        last_name  = normalize_spacing(parts[split_index..].join(" "))

        return [ :review, { reason: "missing_name_part", raw: token } ] if first_name.blank? || last_name.blank?

        [ :person, {
          first_name: first_name,
          last_name: last_name,
          title: title.presence,
          raw: token
        } ]
      end

      def parse_token(token)
        token = normalize_spacing(token)

        return [ :review, { reason: "blank_token", raw: token } ] if token.blank?
        return [ :review, { reason: "suspicious_token", raw: token } ] if suspicious_token?(token)

        if looks_like_collective?(token) || truncation_collective_token?(token)
          return [ :collective, { collective_name: normalize_collective_tail(token), raw: token } ]
        end

        if compact_initial_surname?(token)
          return parse_compact_initial_surname(token)
        end

        if initial_surname_token?(token)
          return parse_initial_surname(token)
        end

        if token.include?(",")
          return parse_inverted_person(token)
        end

        parse_normal_person(token)
      end

      def person_key(first_name, last_name)
        first = canonical(first_name)
        last  = canonical(last_name)
        return nil if first.blank? || last.blank?

        "#{first}|#{last}"
      end

      def person_initial_key(last_name, first_initial)
        last = canonical(last_name)
        initial = first_initial.to_s.downcase
        return nil if last.blank? || initial.blank?

        "#{last}|#{initial}"
      end

      def collective_key(collective_name)
        canonical(normalize_collective_tail(collective_name))
      end
    end

    dry_run = ENV["DRY_RUN"].to_s == "1"

    review_rows = []
    review_publication_ids = []
    migrated_publication_ids = []

    person_cache = {}
    person_initial_cache = Hash.new { |h, k| h[k] = [] }
    collective_cache = {}

    found_existing_author_ids = Set.new
    created_author_ids = Set.new
    created_authors_count = 0
    matched_existing_authors_count = 0

    Author.find_each do |author|
      if author.collective_name.present?
        key = AuthorMigration.collective_key(author.collective_name)
        collective_cache[key] ||= author
      elsif author.first_name.present? && author.last_name.present?
        key = AuthorMigration.person_key(author.first_name, author.last_name)
        person_cache[key] ||= author

        initial = AuthorMigration.initial_of(author.first_name)
        if initial.present?
          initial_key = AuthorMigration.person_initial_key(author.last_name, initial)
          person_initial_cache[initial_key] << author unless person_initial_cache[initial_key].any? { |a| a.id == author.id }
        end
      end
    end

    Publication.find_each do |publication|
      raw_author_list = publication.author_list.to_s

      if raw_author_list.blank?
        review_publication_ids << publication.id
        review_rows << {
          publication_id: publication.id,
          reason: "blank_author_list",
          author_list: raw_author_list,
          parsed_tokens: nil
        }
        next
      end

      next if publication.publication_authorships.exists?

      normalized = AuthorMigration.normalize(raw_author_list)
      normalized, truncation_collectives = AuthorMigration.extract_truncation_collectives(normalized)

      token_status, token_payload = AuthorMigration.build_candidate_tokens(normalized)

      if token_status == :review
        review_publication_ids << publication.id
        review_rows << {
          publication_id: publication.id,
          reason: token_payload[:reason],
          author_list: raw_author_list,
          parsed_tokens: Array(token_payload[:parsed_tokens]).join(" | ")
        }
        next
      end

      tokens = token_payload + truncation_collectives
      parsed_authors = []
      row_failed = false
      row_reason = nil

      tokens.each do |token|
        status, payload = AuthorMigration.parse_token(token)

        case status
        when :person, :collective
          parsed_authors << [ status, payload ]
        when :review
          row_failed = true
          row_reason = payload[:reason]
          break
        else
          row_failed = true
          row_reason = "unknown_parse_status"
          break
        end
      end

      if row_failed || parsed_authors.empty?
        review_publication_ids << publication.id
        review_rows << {
          publication_id: publication.id,
          reason: row_reason || "no_parsed_authors",
          author_list: raw_author_list,
          parsed_tokens: tokens.join(" | ")
        }
        next
      end

      begin
        Publication.transaction do
          used_author_ids = Set.new

          parsed_authors.each_with_index do |(kind, attrs), index|
            author =
              if kind == :collective
                c_key = AuthorMigration.collective_key(attrs[:collective_name])

                existing_collective = collective_cache[c_key]

                if existing_collective
                  found_existing_author_ids << existing_collective.id if existing_collective.persisted?
                  matched_existing_authors_count += 1
                  existing_collective
                else
                  created =
                    unless dry_run
                      Author.create!(
                        author_type: "collective",
                        collective_name: AuthorMigration.normalize_collective_tail(attrs[:collective_name])
                      )
                    else
                      Author.new(
                        author_type: "collective",
                        collective_name: AuthorMigration.normalize_collective_tail(attrs[:collective_name])
                      )
                    end

                  collective_cache[c_key] = created

                  if created.persisted?
                    created_author_ids << created.id
                  end
                  created_authors_count += 1

                  created
                end
              else
                first_name = attrs[:first_name]
                last_name  = attrs[:last_name]
                title      = attrs[:title]

                p_key = AuthorMigration.person_key(first_name, last_name)

                existing = person_cache[p_key]

                if existing
                  found_existing_author_ids << existing.id if existing.persisted?
                  matched_existing_authors_count += 1
                  existing
                elsif AuthorMigration.initials_only?(first_name)
                  initial = AuthorMigration.initial_of(first_name)
                  initial_key = AuthorMigration.person_initial_key(last_name, initial)
                  candidates = person_initial_cache[initial_key]

                  if candidates.size == 1
                    matched = candidates.first
                    person_cache[p_key] ||= matched
                    found_existing_author_ids << matched.id if matched.persisted?
                    matched_existing_authors_count += 1
                    matched
                  elsif candidates.size > 1
                    raise StandardError, "ambiguous_initial_match_for_#{first_name}_#{last_name}"
                  else
                    created =
                      unless dry_run
                        Author.create!(
                          author_type: "person",
                          first_name: first_name,
                          last_name: last_name,
                          title: title
                        )
                      else
                        Author.new(
                          author_type: "person",
                          first_name: first_name,
                          last_name: last_name,
                          title: title
                        )
                      end

                    person_cache[p_key] = created

                    if created.persisted?
                      created_author_ids << created.id
                    end
                    created_authors_count += 1

                    if initial.present?
                      person_initial_cache[initial_key] << created unless person_initial_cache[initial_key].any? { |a| a.id == created.id }
                    end

                    created
                  end
                else
                  created =
                    unless dry_run
                      Author.create!(
                        author_type: "person",
                        first_name: first_name,
                        last_name: last_name,
                        title: title
                      )
                    else
                      Author.new(
                        author_type: "person",
                        first_name: first_name,
                        last_name: last_name,
                        title: title
                      )
                    end

                  person_cache[p_key] = created

                  if created.persisted?
                    created_author_ids << created.id
                  end
                  created_authors_count += 1

                  initial = AuthorMigration.initial_of(first_name)
                  if initial.present?
                    initial_key = AuthorMigration.person_initial_key(last_name, initial)
                    person_initial_cache[initial_key] << created unless person_initial_cache[initial_key].any? { |a| a.id == created.id }
                  end

                  created
                end
              end

            next if used_author_ids.include?(author.id)

            unless dry_run
              PublicationAuthorship.create!(
                publication: publication,
                author: author,
                position: index + 1
              )
            end
            used_author_ids << author.id
          end
        end

        migrated_publication_ids << publication.id
      rescue => e
        review_publication_ids << publication.id
        review_rows << {
          publication_id: publication.id,
          reason: "exception: #{e.class} - #{e.message}",
          author_list: raw_author_list,
          parsed_tokens: tokens.join(" | ")
        }
      end
    end

    review_publication_ids = review_publication_ids.uniq.sort

    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    suffix = dry_run ? "dry_run" : "write"
    review_csv_path = Rails.root.join("tmp", "author_migration_review_v5_#{suffix}_#{timestamp}.csv")
    FileUtils.mkdir_p(review_csv_path.dirname)

    CSV.open(review_csv_path, "w", headers: true) do |csv|
      csv << [ "publication_id", "reason", "author_list", "parsed_tokens" ]

      review_rows.each do |row|
        csv << [
          row[:publication_id],
          row[:reason],
          row[:author_list],
          row[:parsed_tokens]
        ]
      end
    end

    puts
    puts "Author migration finished."
    puts "Mode: #{dry_run ? 'DRY RUN' : 'WRITE'}"
    puts "Publications migrated: #{migrated_publication_ids.size}"
    puts "Publications requiring manual review: #{review_publication_ids.size}"
    puts "Review CSV: #{review_csv_path}"
    puts
    puts "Authors matched or created during migration:"
    puts "Unique existing authors matched: #{found_existing_author_ids.size}"
    puts "Unique new authors created: #{created_author_ids.size}"
    puts "Total unique authors used: #{found_existing_author_ids.size + created_author_ids.size}"
    puts "Total match operations: #{matched_existing_authors_count}"
    puts "Total create operations: #{created_authors_count}"
    puts
    puts "Publication IDs requiring manual review:"
    puts review_publication_ids.join(", ")
  end
end
