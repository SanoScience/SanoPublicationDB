module Publications
  class ExportColumns
    class << self
      def all
        COLUMNS
      end

      def selected(keys)
        chosen = Array(keys).presence || COLUMNS.keys
        chosen &= COLUMNS.keys
        chosen.presence || COLUMNS.keys
      end

      def yes_no(value)
        value ? "yes" : "no"
      end

      def research_group_publications(pub)
        pub.research_group_publications.includes(:research_group).to_a
      end
    end

    COLUMNS = {
      "id" => {
        label: "ID",
        value: ->(pub) { pub.id }
      },
      "title" => {
        label: "Title",
        value: ->(pub) { pub.title }
      },
      "category" => {
        label: "Category",
        value: ->(pub) { pub.category }
      },
      "status" => {
        label: "Status",
        value: ->(pub) { pub.status }
      },
      "authors" => {
        label: "Authors",
        value: ->(pub) { pub.formatted_authors }
      },
      "year" => {
        label: "Year",
        value: ->(pub) { pub.publication_year }
      },
      "link" => {
        label: "Link",
        value: ->(pub) { pub.link }
      },
      "owner_email" => {
        label: "Owner email",
        value: ->(pub) { pub.owner&.email || "imported" }
      },
      "primary_research_group" => {
        label: "Primary research group",
        value: ->(pub) do
            research_group_publications(pub)
            .find(&:is_primary)
            &.research_group
            &.name
        end
      },
      "other_research_groups" => {
        label: "Other research groups",
        value: ->(pub) do
            research_group_publications(pub)
            .reject(&:is_primary)
            .map { |rgp| rgp.research_group&.name }
            .compact
            .join(", ")
        end
      },
      "identifiers" => {
        label: "Identifiers",
        value: ->(pub) { pub.identifiers.map { |i| "#{i.category}: #{i.value}" }.join("; ") }
      },
      "repository_links" => {
        label: "Repository links",
        value: ->(pub) { pub.repository_links.map { |r| "#{r.repository}: #{r.value}" }.join("; ") }
      },
      "conference_name" => {
        label: "Conference name",
        value: ->(pub) { pub.conference&.name }
      },
      "conference_core" => {
        label: "Conference CORE",
        value: ->(pub) { pub.conference&.core }
      },
      "conference_start_date" => {
        label: "Conference start date",
        value: ->(pub) { pub.conference&.start_date }
      },
      "conference_end_date" => {
        label: "Conference end date",
        value: ->(pub) { pub.conference&.end_date }
      },
      "journal_issue_title" => {
        label: "Journal issue title",
        value: ->(pub) { pub.journal_issue&.title }
      },
      "journal_number" => {
        label: "Journal number",
        value: ->(pub) { pub.journal_issue&.journal_num }
      },
      "journal_publisher" => {
        label: "Journal publisher",
        value: ->(pub) { pub.journal_issue&.publisher }
      },
      "journal_volume" => {
        label: "Journal volume",
        value: ->(pub) { pub.journal_issue&.volume }
      },
      "journal_impact_factor" => {
        label: "Journal impact factor",
        value: ->(pub) { pub.journal_issue&.impact_factor }
      },
      "oa_category" => {
        label: "OA category",
        value: ->(pub) { pub.open_access_extension&.category }
      },
      "gold_oa_charges" => {
        label: "Gold OA charges",
        value: ->(pub) { pub.open_access_extension&.gold_oa_charges }
      },
      "gold_oa_funding_source" => {
        label: "Gold OA funding source",
        value: ->(pub) { pub.open_access_extension&.gold_oa_funding_source }
      },
      "kpi_subsidy_points" => {
        label: "KPI: subsidy_points",
        value: ->(pub) { pub.kpi_reporting_extension&.subsidy_points }
      },
      "kpi_polish_medical_researchers" => {
        label: "Are Polish medical researchers involved?",
        value: ->(pub) { yes_no(pub.kpi_reporting_extension&.is_polish_med_researcher_involved) }
      },
      "kpi_methodology_application" => {
        label: "Does describe application of the methodology?",
        value: ->(pub) { yes_no(pub.kpi_reporting_extension&.is_methodology_application) }
      },
      "kpi_new_method" => {
        label: "Does describe new method/technique?",
        value: ->(pub) { yes_no(pub.kpi_reporting_extension&.is_new_method_technique) }
      },
      "kpi_peer_reviewed" => {
        label: "Is peer-reviewed?",
        value: ->(pub) { yes_no(pub.kpi_reporting_extension&.is_peer_reviewed) }
      },
      "kpi_partners" => {
        label: "Is co-publication with partners?",
        value: ->(pub) { yes_no(pub.kpi_reporting_extension&.is_co_publication_with_partners) }
      },
      "kpi_teaming_reporting_period" => {
        label: "Teaming reporting period",
        value: ->(pub) { pub.kpi_reporting_extension&.teaming_reporting_period }
      },
      "kpi_invoice_number" => {
        label: "Invoice number",
        value: ->(pub) { pub.kpi_reporting_extension&.invoice_number }
      },
      "kpi_pbn" => {
        label: "PBN",
        value: ->(pub) { yes_no(pub.kpi_reporting_extension&.pbn) }
      },
      "kpi_jcr" => {
        label: "JCR",
        value: ->(pub) { yes_no(pub.kpi_reporting_extension&.jcr) }
      },
      "kpi_ft_portal" => {
        label: "FT portal",
        value: ->(pub) { yes_no(pub.kpi_reporting_extension&.is_added_ft_portal) }
      }
    }.freeze

    private_class_method :yes_no, :research_group_publications
  end
end