# app/services/authors/sort_validator.rb
module Authors
  class SortValidator
    DEFAULT_SORT = "id_desc".freeze

    ALLOWED_SORTS = {
      "id_desc" => "authors.id DESC",
      "name_asc" => <<~SQL.squish,
        CASE
          WHEN COALESCE(authors.collective_name, '') <> ''
            THEN unaccent(lower(authors.collective_name))
          ELSE
            unaccent(lower(trim(concat_ws(' ', authors.title, authors.first_name, authors.last_name))))
        END ASC,
        authors.id ASC
      SQL
      "name_desc" => <<~SQL.squish,
        CASE
          WHEN COALESCE(authors.collective_name, '') <> ''
            THEN unaccent(lower(authors.collective_name))
          ELSE
            unaccent(lower(trim(concat_ws(' ', authors.title, authors.first_name, authors.last_name))))
        END DESC,
        authors.id DESC
      SQL
      "publications_count_desc" => "COUNT(DISTINCT publication_authorships.publication_id) DESC, authors.id ASC",
      "publications_count_asc" => "COUNT(DISTINCT publication_authorships.publication_id) ASC, authors.id ASC"
    }.freeze

    LABELS = {
      "id_desc" => "Newest first",
      "name_asc" => "Name A–Z",
      "name_desc" => "Name Z–A",
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