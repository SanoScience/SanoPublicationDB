class Api::StatisticsController < ActionController::API
    def publications_count
        publications_count = Publication.count
        render json: publications_count
    end

    def conferences_count
        conferences_count = Conference.count
        render json: conferences_count
    end

    def conference_with_most_publications
        conference_with_most_publications = Conference.joins(:publications)
                    .select("conferences.*, COUNT(publications.id) as publication_count")
                    .group("conferences.id")
                    .order("publication_count DESC")
                    .first
        render json: conference_with_most_publications
    end

    def journals_count
        journals_count = JournalIssue.count
        render json: journals_count
    end

    def journal_with_most_publications
        journal_with_most_publications = JournalIssue.joins(:publications)
                    .select("journal_issues.*, COUNT(publications.id) as publication_count")
                    .group("journal_issues.id")
                    .order("publication_count DESC")
                    .first
        render json: journal_with_most_publications
    end

    def publications_by_research_groups_count
        publications_by_research_groups_count = ResearchGroupPublication.group(:research_group).count
        render json: publications_by_research_groups_count
    end

    def publications_by_category_count
        publications_by_category_count = Publication.group(:category).count
        render json: publications_by_category_count
    end

    def publications_by_status_count
        publications_by_status_count = Publication.group(:status).count
        render json: publications_by_status_count
    end

    def average_impact_factor
        average_impact_factor = JournalIssue.joins(:publications).average(:impact_factor)
        render json: average_impact_factor
    end

    def open_access_publications_count
        open_access_publications_count = OpenAccessExtension.count
        render json: open_access_publications_count
    end

    def open_access_publications_percentage
        open_access_publications_percentage = OpenAccessExtension.count / Publication.count.to_f * 100
        render json: open_access_publications_percentage
    end

    def green_open_access_publications_count
        green_open_access_publications_count = OpenAccessExtension.where(category: "green").count
        render json: green_open_access_publications_count
    end

    def gold_open_access_publications_count
        gold_open_access_publications_count = OpenAccessExtension.where(category: "gold").count
        render json: gold_open_access_publications_count
    end

    def average_subsidy_points
        average = KpiReportingExtension.where.not(subsidy_points: [ nil, 0 ]).average(:subsidy_points)
        formatted_average = format("%.5f", average)
        render json: formatted_average
    end
end
