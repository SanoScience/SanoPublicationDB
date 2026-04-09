# app/models/concerns/author_search_sql.rb
module AuthorSearchSql
  extend ActiveSupport::Concern

  class_methods do
    def normalized_like_pattern(term)
      "%#{term.to_s.strip.downcase.gsub(/[[:space:]]+/, " ")}%"
    end

    def author_name_expression(table)
      Arel::Nodes::NamedFunction.new(
        "unaccent",
        [
          Arel::Nodes::NamedFunction.new(
            "lower",
            [
              Arel::Nodes::NamedFunction.new(
                "concat_ws",
                [
                  Arel::Nodes.build_quoted(" "),
                  Arel::Nodes::NamedFunction.new("coalesce", [ table[:title], Arel::Nodes.build_quoted("") ]),
                  Arel::Nodes::NamedFunction.new("coalesce", [ table[:first_name], Arel::Nodes.build_quoted("") ]),
                  Arel::Nodes::NamedFunction.new("coalesce", [ table[:last_name], Arel::Nodes.build_quoted("") ]),
                  Arel::Nodes::NamedFunction.new("coalesce", [ table[:collective_name], Arel::Nodes.build_quoted("") ])
                ]
              )
            ]
          )
        ]
      )
    end

    def normalized_pattern_node(term)
      Arel::Nodes::NamedFunction.new(
        "unaccent",
        [
          Arel::Nodes::NamedFunction.new(
            "lower",
            [ Arel::Nodes.build_quoted(normalized_like_pattern(term)) ]
          )
        ]
      )
    end
  end
end
