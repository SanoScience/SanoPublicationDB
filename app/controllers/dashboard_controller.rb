class DashboardController < ApplicationController
  def index
    @all_publications = Publication.includes(:kpi_reporting_extension, :journal_issue, :research_groups).to_a

    @q = Publication.ransack(params[:q])
    @filtered_publications = @q.result
                               .includes(:kpi_reporting_extension, :journal_issue, :research_groups)
                               .left_joins(:kpi_reporting_extension)
                               .distinct
                               .to_a

    @selected_categories = params.dig(:q, :category_in) || Publication.categories.keys

    @dashboard = DashboardPresenter.new(@all_publications, @filtered_publications, helpers)
  end
end
