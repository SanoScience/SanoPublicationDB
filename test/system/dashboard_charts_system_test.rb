require "application_system_test_case"

class DashboardChartsSystemTest < ApplicationSystemTestCase
  test "renders Chart.js canvases correctly" do
    visit dashboard_path

    # Chartkick mounts <canvas>
    assert_selector "#chart-1 canvas", wait: 5
    assert_selector "#chart-2 canvas"
    assert_no_selector "#chart-1", text: "Loading..."

    # Ensure non-zero canvas dimensions
    canvas = find("#chart-1 canvas")
    assert_operator canvas.rect.width, :>, 0
    assert_operator canvas.rect.height, :>, 0
  end

  test "re-renders charts properly after Turbo Frame filtering" do
    excluded_pub = publications(:pub_no_conf_jour)

    visit dashboard_path
    assert_selector "#chart-1 canvas", wait: 5
    assert_text excluded_pub.title

    # Input -> Stimulus filter-form -> Turbo Frame update
    fill_in "q_title_cont", with: "Test"

    assert_no_text excluded_pub.title
    assert_selector "#chart-1 canvas", wait: 5
    assert_no_selector "#chart-1", text: "Loading..."
  end
end
