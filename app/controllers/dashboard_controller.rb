class DashboardController < ApplicationController
  def index
    @all_publications = Publication.includes(:kpi_reporting_extension, :journal_issue, :research_groups).to_a

    @total_count = @all_publications.size
    @journal_count = @all_publications.count(&:journal_article?)
    @conf_count = @all_publications.count { |p| p.conference_manuscript? || p.conference_abstract? }
    @count_140 = @all_publications.count { |p| p.kpi_reporting_extension&.subsidy_points.to_i >= 140 }
    @count_with_points = @all_publications.count { |p| p.kpi_reporting_extension&.subsidy_points.present? }

    counts_by_type = @all_publications.group_by(&:category).transform_values(&:size)
    @global_type_counts = Publication.categories.keys.index_with { |t| counts_by_type[t] || 0 }

    @q = Publication.ransack(params[:q])
    @filtered_publications = @q.result
                               .includes(:kpi_reporting_extension, :journal_issue, :research_groups)
                               .left_joins(:kpi_reporting_extension)
                               .distinct
                               .to_a

    @selected_categories = params.dig(:q, :category_in) || Publication.categories.keys

    @year_chart_data = build_year_chart_data(@filtered_publications)
    @team_chart_data = build_team_chart_data(@filtered_publications)
    @team_multiples = build_team_multiples(@filtered_publications)

    pubs_140 = @filtered_publications.select { |p| p.kpi_reporting_extension&.subsidy_points.to_i >= 140 }
    @year_140_chart_data = build_year_chart_data(pubs_140)
    @team_140_chart_data = build_team_chart_data(pubs_140)
  end

  private

  def build_year_chart_data(pubs)
    all_years = pubs.map { |p| p.publication_year || "Unknown" }
                    .uniq
                    .sort_by { |y| [y == "Unknown" ? 1 : 0, y.to_i] }

    Publication.categories.keys.map do |type_key|
        type_pubs = pubs.select { |p| p.category == type_key }
        counts = type_pubs.group_by { |p| p.publication_year || "Unknown" }.transform_values(&:size)

        data = all_years.index_with { |year| counts[year] || 0 }

        { name: type_key.humanize, data: data }
    end
  end

  def build_team_chart_data(pubs)
    counts = Hash.new(0)
    pubs.each do |p|
      groups = p.research_groups.map(&:name)
      groups = ["Unassigned"] if groups.empty?
      groups.each { |g| counts[helpers.dashboard_team_short(g)] += 1 }
    end

    counts.sort_by { |_team, count| -count }.to_h
  end

  def build_team_multiples(pubs)
    team_pubs_hash = Hash.new { |h, k| h[k] = [] }
    pubs.each do |p|
      groups = p.research_groups.map(&:name)
      groups = ["Unassigned"] if groups.empty?
      groups.each { |g| team_pubs_hash[g] << p }
    end

    sorted_teams = team_pubs_hash.sort_by { |_team, list| -list.size }

    sorted_teams.map do |team_name, team_pubs|
      {
        name: helpers.dashboard_team_short(team_name),
        count: team_pubs.size,
        chart_data: build_year_chart_data(team_pubs)
      }
    end
  end
end
