module Publications
  class SortValidator
    ALLOWED_SORTS = {
      "title_asc" => "publications.title ASC",
      "title_desc" => "publications.title DESC",
      "publication_date_asc" => "publications.publication_date ASC",
      "publication_date_desc" => "publications.publication_date DESC",
      "journal_issue_title_asc" => "journal_issues.title ASC NULLS LAST",
      "journal_issue_title_desc" => "journal_issues.title DESC NULLS LAST",
      "conference_name_asc" => "conferences.name ASC NULLS LAST",
      "conference_name_desc" => "conferences.name DESC NULLS LAST",
      "journal_issue_impact_factor_asc" => "journal_issues.impact_factor ASC NULLS LAST",
      "journal_issue_impact_factor_desc" => "journal_issues.impact_factor DESC NULLS LAST",
      "subsidy_points_asc" => "kpi_reporting_extensions.subsidy_points ASC NULLS LAST",
      "subsidy_points_desc" => "kpi_reporting_extensions.subsidy_points DESC NULLS LAST"
    }.freeze

    def self.safe_order(param)
      return nil unless ALLOWED_SORTS.key?(param)

      Arel.sql(ALLOWED_SORTS[param])
    end

    def self.options
      ALLOWED_SORTS
    end
  end
end
