require "parallel"
require "set"
require "jaro_winkler"

module Authors
  class DuplicateDetector
    AuthorRecord = Struct.new(
      :id,
      :first_name,
      :last_name,
      :collective_name,
      :person,
      :collective,
      :title,
      :person_variants,
      :reversed_person_variants,
      :normalized_collective_name,
      :compact_collective_name,
      :collective_tokens,
      keyword_init: true
    )

    Group = Struct.new(:authors, keyword_init: true)

    def initialize(config: nil)
        base_threshold = env_float("DUPLICATE_DETECTOR_BASE_THRESHOLD", 0.93)
        default_processes = [Etc.nprocessors - 1, 1].max

        @config = {
            person_person_threshold: base_threshold,
            person_collective_threshold: base_threshold - 0.01,
            collective_collective_threshold: base_threshold,
            token_threshold: base_threshold - 0.02,
            very_strong_token_match: [base_threshold + 0.04, 1.0].min,
            probable_token_typo_match: [base_threshold - 0.13, 0.0].max,
            strong_full_name_match: base_threshold - 0.03,
            short_token_exact_only_len: env_int("DUPLICATE_DETECTOR_SHORT_TOKEN_EXACT_ONLY_LEN", 2),
            parallel_processes: [env_int("PARALLEL_PROCESSES", default_processes), 1].max,
            slice_size: [env_int("DUPLICATE_DETECTOR_SLICE_SIZE", 50), 1].max
        }
    end

    def call
      records = build_records
      return [] if records.size < 2

      edge_pairs = Parallel.flat_map(left_index_slices(records.size), in_processes: @config[:parallel_processes]) do |left_indices|
        pairs = []

        left_indices.each do |left_index|
          left = records[left_index]

          ((left_index + 1)...records.size).each do |right_index|
            right = records[right_index]
            pairs << [left.id, right.id] if match_pair(left, right)
          end
        end

        pairs
      end

      build_groups(edge_pairs)
    end

    private

    def env_float(key, default)
        Float(ENV.fetch(key, default))
    rescue ArgumentError, TypeError
        default
    end

    def env_int(key, default)
        Integer(ENV.fetch(key, default))
    rescue ArgumentError, TypeError
        default
    end

    def build_records
      Author.order(:id).load.map do |author|
        AuthorRecord.new(
          id: author.id,
          first_name: normalize(author.first_name),
          last_name: normalize(author.last_name),
          collective_name: author.collective_name,
          person: author.person?,
          collective: author.collective?,
          title: normalize(author.title),
          person_variants: person_variants_for(author),
          reversed_person_variants: reversed_person_variants_for(author),
          normalized_collective_name: normalize(author.collective_name),
          compact_collective_name: compact(author.collective_name),
          collective_tokens: tokens(author.collective_name)
        )
      end
    end

    def left_index_slices(size)
      (0...size).each_slice(@config[:slice_size]).to_a
    end

    def match_pair(left, right)
      if left.person && right.person
        person_person_match?(left, right)
      elsif left.collective && right.collective
        collective_collective_match?(left, right)
      else
        person_collective_match?(left, right)
      end
    end

    def person_person_match?(left, right)
      ff = token_similarity(left.first_name, right.first_name)
      ll = token_similarity(left.last_name, right.last_name)
      fl = token_similarity(left.first_name, right.last_name)
      lf = token_similarity(left.last_name, right.first_name)

      direct_full = best_similarity(left.person_variants, right.person_variants)
      reversed_full = best_similarity(left.person_variants, right.reversed_person_variants)

      return true if ff >= @config[:token_threshold] &&
                     ll >= @config[:token_threshold] &&
                     direct_full >= @config[:person_person_threshold]

      return true if fl >= @config[:token_threshold] &&
                     lf >= @config[:token_threshold] &&
                     reversed_full >= @config[:person_person_threshold]

      return true if ll >= @config[:very_strong_token_match] &&
                     ff >= @config[:probable_token_typo_match] &&
                     direct_full >= @config[:strong_full_name_match]

      return true if ff >= @config[:very_strong_token_match] &&
                     ll >= @config[:probable_token_typo_match] &&
                     direct_full >= @config[:strong_full_name_match]

      false
    end

    def collective_collective_match?(left, right)
      direct = similarity(left.normalized_collective_name, right.normalized_collective_name)
      compact_score = similarity(left.compact_collective_name, right.compact_collective_name)

      [direct, compact_score].max >= @config[:collective_collective_threshold]
    end

    def person_collective_match?(left, right)
      person = left.person ? left : right
      collective = left.collective ? left : right

      full_scores = person.person_variants.map do |variant|
        [
          similarity(collective.normalized_collective_name, variant),
          similarity(collective.compact_collective_name, compact(variant))
        ].max
      end

      reversed_scores = person.reversed_person_variants.map do |variant|
        [
          similarity(collective.normalized_collective_name, variant),
          similarity(collective.compact_collective_name, compact(variant))
        ].max
      end

      first_score = token_similarity(collective.normalized_collective_name, person.first_name)
      last_score = token_similarity(collective.normalized_collective_name, person.last_name)

      contains_person_tokens =
        collective.collective_tokens.any? { |token| token_similarity(token, person.first_name) >= @config[:token_threshold] } &&
        collective.collective_tokens.any? { |token| token_similarity(token, person.last_name) >= @config[:token_threshold] }

      best_full = (full_scores + reversed_scores + [first_score, last_score]).max || 0.0

      best_full >= @config[:person_collective_threshold] || contains_person_tokens
    end

    def build_groups(edge_pairs)
      return [] if edge_pairs.empty?

      author_ids = edge_pairs.flatten.uniq

      authors_by_id = Author
        .left_joins(:publication_authorships)
        .where(id: author_ids)
        .select("authors.*, COUNT(DISTINCT publication_authorships.publication_id) AS publications_count")
        .group("authors.id")
        .index_by(&:id)

      adjacency = Hash.new { |hash, key| hash[key] = Set.new }

      edge_pairs.each do |left_id, right_id|
        adjacency[left_id] << right_id
        adjacency[right_id] << left_id
      end

      visited = Set.new
      groups = []

      adjacency.keys.each do |author_id|
        next if visited.include?(author_id)

        stack = [author_id]
        ids = []

        until stack.empty?
          current_id = stack.pop
          next if visited.include?(current_id)

          visited << current_id
          ids << current_id

          adjacency[current_id].each do |neighbor_id|
            stack << neighbor_id unless visited.include?(neighbor_id)
          end
        end

        groups << Group.new(
          authors: ids.sort.map { |id| authors_by_id[id] }.compact
        )
      end

      groups.sort_by { |group| group.authors.map(&:id).min }
    end

    def person_variants_for(author)
      [
        normalize([author.first_name, author.last_name].compact.join(" ")),
        normalize([author.title, author.first_name, author.last_name].compact.join(" "))
      ].reject(&:blank?).uniq
    end

    def reversed_person_variants_for(author)
      [
        normalize([author.last_name, author.first_name].compact.join(" ")),
        normalize([author.last_name, author.first_name, author.title].compact.join(" "))
      ].reject(&:blank?).uniq
    end

    def best_similarity(left_variants, right_variants)
      left_variants.product(right_variants).map do |left, right|
        [
          similarity(left, right),
          similarity(compact(left), compact(right))
        ].max
      end.max || 0.0
    end

    def similarity(left, right)
      return 0.0 if left.blank? || right.blank?

      JaroWinkler.similarity(left, right)
    end

    def token_similarity(left, right)
      return 0.0 if left.blank? || right.blank?

      if [left.length, right.length].min <= @config[:short_token_exact_only_len]
        return left == right ? 1.0 : 0.0
      end

      [
        similarity(left, right),
        similarity(compact(left), compact(right))
      ].max
    end

    def normalize(value)
      I18n.transliterate(value.to_s)
          .downcase
          .gsub(/[^a-z0-9]+/, " ")
          .squeeze(" ")
          .strip
    end

    def compact(value)
      normalize(value).delete(" ")
    end

    def tokens(value)
      normalize(value).split
    end
  end
end
