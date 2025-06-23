class Api::StatisticsController < ActionController::API
    def publications_count
        publications_count = Publication.where.not(status: "submitted").count
        render json: publications_count
    end

    def conferences_count
        conferences_count = Conference.joins(:publications)
                                    .where.not(publications: { status: "submitted" })
                                    .distinct
                                    .count
        render json: conferences_count
    end

    def conference_with_most_publications
        conference_with_most_publications = Conference.joins(:publications)
                    .where.not(publications: { status: "submitted" })
                    .distinct
                    .select("conferences.*, COUNT(publications.id) as publication_count")
                    .group("conferences.id")
                    .order("publication_count DESC")
                    .first
        render json: conference_with_most_publications
    end

    def journals_count
        journals_count = JournalIssue.joins(:publications)
                                    .where.not(publications: { status: "submitted" })
                                    .distinct
                                    .count
        render json: journals_count
    end

    def journal_with_most_publications
        journal_with_most_publications = JournalIssue.joins(:publications)
                    .where.not(publications: { status: "submitted" })
                    .distinct
                    .select("journal_issues.*, COUNT(publications.id) as publication_count")
                    .group("journal_issues.id")
                    .order("publication_count DESC")
                    .first
        render json: journal_with_most_publications
    end

    def publications_by_research_groups_count
        publications_by_research_groups_count = ResearchGroupPublication.joins(:publication)
                                                                   .where.not(publications: { status: "submitted" })
                                                                   .group(:research_group)
                                                                   .count
                                                                   .transform_keys { |key| ResearchGroupPublication.research_groups[key] }
        render json: publications_by_research_groups_count
    end

    def publications_by_category_count
        publications_by_category_count = Publication.where.not(status: "submitted").group(:category).count
        render json: publications_by_category_count
    end

    def publications_by_status_count
        publications_by_status_count = Publication.group(:status).count
        render json: publications_by_status_count
    end

    def average_impact_factor
        average_impact_factor = JournalIssue.joins(:publications)
                                            .where.not(publications: { status: "submitted" })
                                            .where.not(impact_factor: [ nil, 0 ])
                                            .average(:impact_factor)
        formatted_average = average_impact_factor ? format("%.2f", average_impact_factor) : 0 
        render json: formatted_average
    end

    def open_access_publications_count
        open_access_publications_count = OpenAccessExtension.joins(:publication)
                                                            .where.not(publications: { status: "submitted" })
                                                            .count
        render json: open_access_publications_count
    end

    def open_access_publications_percentage
        total = Publication.where.not(status: "submitted").count
        if total == 0
            render json: "0.00"
        else
            open_access_count = OpenAccessExtension.joins(:publication)
                                .where.not(publications: { status: "submitted" })
                                .count
            percentage = open_access_count.to_f / total * 100
            formatted_percentage = format("%.2f", percentage)
            render json: formatted_percentage
        end
    end    

    def green_open_access_publications_count
        green_open_access_publications_count = OpenAccessExtension.joins(:publication)
                                                                   .where.not(publications: { status: "submitted" })
                                                                   .where(category: "green")
                                                                   .count
        render json: green_open_access_publications_count
    end

    def gold_open_access_publications_count
        gold_open_access_publications_count = OpenAccessExtension.joins(:publication)
                                                                   .where.not(publications: { status: "submitted" })
                                                                   .where(category: "gold")
                                                                   .count
        render json: gold_open_access_publications_count
    end

    def average_subsidy_points
        average_subsidy_points = KpiReportingExtension.joins(:publication)
                                      .where.not(publications: { status: "submitted" })
                                      .where.not(subsidy_points: [ nil, 0 ])
                                      .average(:subsidy_points)
        formatted_average = average_subsidy_points ? format("%.2f", average_subsidy_points) : 0
        render json: formatted_average
    end
end
