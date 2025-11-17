module Publications
  class SortValidator
    DEFAULT_SORT = "id_desc".freeze

    ALLOWED_SORTS = {
      "id_desc" => "publications.id DESC",
      "title_asc" => "publications.title ASC",
      "title_desc" => "publications.title DESC",
      "publication_year_asc" => "publications.publication_year ASC NULLS LAST",
      "publication_year_desc" => "publications.publication_year DESC NULLS LAST",
      "journal_issue_title_asc" => "journal_issues.title ASC NULLS LAST",
      "journal_issue_title_desc" => "journal_issues.title DESC NULLS LAST",
      "conference_name_asc" => "conferences.name ASC NULLS LAST",
      "conference_name_desc" => "conferences.name DESC NULLS LAST",
      "journal_issue_impact_factor_asc" => "journal_issues.impact_factor ASC NULLS LAST",
      "journal_issue_impact_factor_desc" => "journal_issues.impact_factor DESC NULLS LAST",
      "subsidy_points_asc" => "kpi_reporting_extensions.subsidy_points ASC NULLS LAST",
      "subsidy_points_desc" => "kpi_reporting_extensions.subsidy_points DESC NULLS LAST"
    }.freeze

    LABELS = {
      "id_desc" => "Newest first",
      "title_asc" => "Title ↑",
      "title_desc" => "Title ↓",
      "publication_year_asc" => "Publication year ↑",
      "publication_year_desc" => "Publication year ↓",
      "journal_issue_title_asc" => "Journal issue title ↑",
      "journal_issue_title_desc" => "Journal issue title ↓",
      "conference_name_asc" => "Conference name ↑",
      "conference_name_desc" => "Conference name ↓",
      "journal_issue_impact_factor_asc" => "Journal issue impact factor ↑",
      "journal_issue_impact_factor_desc" => "Journal issue impact factor ↓",
      "subsidy_points_asc" => "Subsidy points ↑",
      "subsidy_points_desc" => "Subsidy points ↓"
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
