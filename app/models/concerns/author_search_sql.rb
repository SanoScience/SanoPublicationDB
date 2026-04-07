# app/models/concerns/author_search_sql.rb
module AuthorSearchSql
  extend ActiveSupport::Concern

  class_methods do
    def normalized_author_name_sql(table_name = "authors")
      <<~SQL.squish
        unaccent(lower(concat_ws(' ',
          #{table_name}.title,
          #{table_name}.first_name,
          #{table_name}.last_name,
          #{table_name}.collective_name
        )))
      SQL
    end

    def normalized_like_pattern(term)
      "%#{ApplicationRecord.sanitize_sql_like(term.to_s.strip)}%"
    end
  end
end
