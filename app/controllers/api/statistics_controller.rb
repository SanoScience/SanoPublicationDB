class Api::StatisticsController < ActionController::API
    def publications_count
        @publications_count = Publication.count
        render json: @publications_count
    end

    def conferences_count
        @conferences_count = Conference.count
        render json: @conferences_count
    end
    
    def publications_by_research_groups_count
        @publications_by_research_groups_count = ResearchGroupPublication.group(:research_group).count
        render json: @publications_by_research_groups_count
    end

    def publications_by_category_count
        @publications_by_category_count = Publication.group(:category).count
        render json: @publications_by_category_count
    end

    def publications_by_status_count
        @publications_by_status_count = Publication.group(:status).count
        render json: @publications_by_status_count
    end
    
    def average_impact_factor
        @average_impact_factor = JournalIssue.joins(:publications).average(:impact_factor)
        render json: @average_impact_factor
    end
end
