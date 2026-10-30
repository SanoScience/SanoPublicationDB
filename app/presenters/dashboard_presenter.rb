class DashboardPresenter
  attr_reader :all_publications, :filtered_publications

  def initialize(all_publications, filtered_publications, helpers)
    @all_publications = all_publications
    @filtered_publications = filtered_publications
    @helpers = helpers
  end

  def total_count; @all_publications.size; end
  def journal_count; @all_publications.count(&:journal_article?); end
  def conf_count; @all_publications.count { |p| p.conference_manuscript? || p.conference_abstract? }; end
  def count_140; @all_publications.count { |p| p.kpi_reporting_extension&.subsidy_points.to_i >= 140 }; end
  def count_with_points; @all_publications.count { |p| p.kpi_reporting_extension&.subsidy_points.present? }; end

  def global_type_counts
    counts = @all_publications.group_by(&:category).transform_values(&:size)
    Publication.categories.keys.index_with { |t| counts[t] || 0 }
  end

  def year_chart_data(pubs = @filtered_publications)
    all_years = pubs.map { |p| p.publication_year || "Unknown" }
                    .uniq
                    .sort_by { |y| [y == "Unknown" ? 1 : 0, y.to_i] }

    Publication.categories.keys.map do |type_key|
      type_pubs = pubs.select { |p| p.category == type_key }
      counts    = type_pubs.group_by { |p| p.publication_year || "Unknown" }.transform_values(&:size)

      { name: type_key.humanize, data: all_years.index_with { |y| counts[y] || 0 } }
    end
  end

  def team_chart_data(pubs = @filtered_publications)
    group_by_team(pubs)
      .transform_keys { |team| @helpers.dashboard_team_short(team) }
      .transform_values(&:size)
      .sort_by { |_, count| -count }
      .to_h
  end

  def team_multiples
    group_by_team(@filtered_publications)
      .sort_by { |_, team_pubs| -team_pubs.size }
      .map do |team_name, team_pubs|
        {
          name: @helpers.dashboard_team_short(team_name),
          count: team_pubs.size,
          chart_data: year_chart_data(team_pubs)
        }
      end
  end

  def year_140_chart_data
    year_chart_data(pubs_140)
  end

  def team_140_chart_data
    team_chart_data(pubs_140)
  end

  private

  def pubs_140
    @pubs_140 ||= @filtered_publications.select { |p| p.kpi_reporting_extension&.subsidy_points.to_i >= 140 }
  end

  def group_by_team(pubs)
    pubs.each_with_object(Hash.new { |h, k| h[k] = [] }) do |pub, hash|
      primary_groups = pub.research_group_publications
                          .select(&:is_primary?)
                          .map { |rgp| rgp.research_group.name }

      groups = primary_groups.presence || ["Unassigned"]
      groups.each { |g| hash[g] << pub }
    end
  end
end
