require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @total_count = Publication.count
    @journal_count = Publication.where(category: :journal_article).count
    @conference_count = Publication.where(category: %i[conference_manuscript conference_abstract]).count
  end

  test "renders summary cards and publication table for guest" do
    get dashboard_path
    assert_response :success

    page_text = document_root_element.text.squish
    assert_includes page_text, "Total publications #{@total_count}"
    assert_includes page_text, "Journal articles #{@journal_count}"
    assert_includes page_text, "Conference-related #{@conference_count}"

    assert_select "table tbody tr", count: @total_count
  end

  test "attributes only primary research team and latest citation snapshot" do
    pub1 = publications(:pub1)
    primary_group = research_groups(:group1)
    secondary_group = research_groups(:group2)
    latest_citations = citation_counts(:openalex15).count
    summed_citations = latest_citations + citation_counts(:openalex_old).count

    get dashboard_path
    assert_response :success

    assert_select "table tbody tr", text: /#{Regexp.escape(pub1.title)}.*#{Regexp.escape(primary_group.name)}.*#{latest_citations}/m
    assert_select "table tbody tr", text: /\b#{Regexp.escape(secondary_group.name)}\b/, count: 0
    assert_select "table tbody tr", text: /#{Regexp.escape(pub1.title)}.*\b#{summed_citations}\b/m, count: 0
  end

  test "filters statistics and table rows via Ransack params" do
    query = "Test"
    expected_count = Publication.where("title ILIKE ?", "%#{query}%").count
    excluded_pub = publications(:pub_no_conf_jour)

    get dashboard_path, params: { q: { title_cont: query } }
    assert_response :success

    page_text = document_root_element.text.squish
    assert_includes page_text, "Total publications #{@total_count}"
    assert_includes page_text, "Showing #{expected_count} of #{@total_count} publications"

    assert_select "table tbody tr", count: expected_count
    assert_select "table tbody tr", text: /#{Regexp.escape(excluded_pub.title)}/, count: 0
  end

  test "renders correctly when database has no publications or citations" do
    CitationCount.delete_all
    ResearchGroupPublication.delete_all
    Publication.delete_all

    get dashboard_path
    assert_response :success

    page_text = document_root_element.text.squish
    assert_includes page_text, "Total publications 0"
    assert_select "table tbody tr", count: 0
  end
end
