# app/services/authors/sort_validator.rb

module Authors
  class SortValidator
    DEFAULT_SORT = "surname_asc".freeze

    SURNAME_SORT_SQL = <<~SQL.squish.freeze
      CASE
        WHEN COALESCE(authors.collective_name, '') <> ''
          THEN unaccent(lower(authors.collective_name))
        ELSE
          unaccent(lower(trim(concat_ws(' ', authors.last_name, authors.first_name, authors.title))))
      END
    SQL

    FIRST_NAME_SORT_SQL = <<~SQL.squish.freeze
      CASE
        WHEN COALESCE(authors.collective_name, '') <> ''
          THEN unaccent(lower(authors.collective_name))
        ELSE
          unaccent(lower(trim(concat_ws(' ', authors.first_name, authors.last_name, authors.title))))
      END
    SQL

    ALLOWED_SORTS = {
      "surname_asc" => <<~SQL.squish.freeze,
        #{SURNAME_SORT_SQL} ASC,
        authors.id ASC
      SQL
      "surname_desc" => <<~SQL.squish.freeze,
        #{SURNAME_SORT_SQL} DESC,
        authors.id DESC
      SQL
      "first_name_asc" => <<~SQL.squish.freeze,
        #{FIRST_NAME_SORT_SQL} ASC,
        authors.id ASC
      SQL
      "first_name_desc" => <<~SQL.squish.freeze,
        #{FIRST_NAME_SORT_SQL} DESC,
        authors.id DESC
      SQL
      "publications_count_desc" => "COUNT(DISTINCT publication_authorships.publication_id) DESC, authors.id ASC".freeze,
      "publications_count_asc" => "COUNT(DISTINCT publication_authorships.publication_id) ASC, authors.id ASC".freeze
    }.freeze

    LABELS = {
      "surname_asc" => "Surname A–Z",
      "surname_desc" => "Surname Z–A",
      "first_name_asc" => "First name A–Z",
      "first_name_desc" => "First name Z–A",
      "publications_count_desc" => "Most publications",
      "publications_count_asc" => "Fewest publications"
    }.freeze

    def self.safe_order(param)
      return nil unless ALLOWED_SORTS.key?(param)

      Arel.sql(ALLOWED_SORTS[param])
    end

    def self.default_key
      DEFAULT_SORT
    end

    def self.default_order
      Arel.sql(ALLOWED_SORTS[DEFAULT_SORT])
    end

    def self.options
      ALLOWED_SORTS.keys.index_with do |key|
        LABELS[key] || key.humanize
      end
    end
  end
end
