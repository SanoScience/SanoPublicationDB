module DashboardHelper
  def dashboard_team_short(team)
    team.to_s
        .gsub(/\band\b/i, "&")
        .gsub(/\bgroup\b/i, "")
        .squish
  end

  def points_badge(points)
    return tag.span("no data", class: "badge bg-light text-muted border fw-normal") if points.nil?
    return tag.span(points, class: "badge bg-warning text-dark border border-warning fw-bold") if points >= 140

    tag.span(points, class: "badge bg-light text-dark border fw-normal")
  end

  def citations_badge(count)
    return tag.span("0", class: "badge bg-light text-muted border fw-normal") if count.nil? || count.zero?

    tag.span(count, class: "badge bg-info text-dark border border-info fw-semibold")
  end
end
