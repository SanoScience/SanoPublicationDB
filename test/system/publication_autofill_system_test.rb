require "application_system_test_case"

class PublicationsAutofillSystemTest < ApplicationSystemTestCase
  include SystemTestsHelper

  def setup
    @user = users(:user)
    @valid_doi = "10.1093/cercor/bhad380"
  end

  test "autofill highlights fields and shows error on submit if unreviewed" do
    sign_in @user
    visit new_publication_path

    fill_in "openalex-doi-input", with: @valid_doi
    click_on "Search & Autofill"

    assert_text "Data successfully loaded from OpenAlex!", wait: 5
    assert_selector ".needs-verification", minimum: 1

    click_on "Create Publication"
    assert_text "Please review all highlighted auto-filled fields. Click on them to confirm they are correct before saving."
  end

  test "clicking all highlighted fields removes highlights and allows submission" do
    sign_in @user
    visit new_publication_path

    fill_in "openalex-doi-input", with: @valid_doi
    click_on "Search & Autofill"

    assert_text "Data successfully loaded from OpenAlex!", wait: 5
    assert_selector ".needs-verification", minimum: 1

    all(".needs-verification").each do |field|
      field.click
    end

    assert_no_selector ".needs-verification"

    if all(".research-group .nested-fields").empty?
      click_on "Add Research Group"
    end
    find(".research-group select").all("option")[1].select_option

    if all(".kpi-reporting-extension .nested-fields").empty?
      click_on "Add KPI Reporting Extension"
    end

    select "Yes", from: "New Method/Technique"
    select "Yes", from: "Methodology Application"
    select "Yes", from: "Polish Medical Researcher Involved"
    select "Yes", from: "Peer Reviewed"
    select "Yes", from: "Co-Publication with Partners"

    assert_difference "Publication.count", 1 do
      click_on "Create Publication"

      assert_no_text "Please review all highlighted auto-filled fields. Click on them to confirm they are correct before saving."
      assert_text "Publication was successfully created"
    end
  end

  test "autofill clears previously entered data before inserting new data" do
    sign_in @user
    visit new_publication_path

    fill_in "Title", with: "Manual Title"
    fill_in "openalex-doi-input", with: @valid_doi

    click_on "Search & Autofill"

    assert_text "Data successfully loaded from OpenAlex!", wait: 5
    assert_no_field "Title", with: "Manual Title"
  end

  test "invalid doi shows error message and retains manually entered data" do
    sign_in @user
    visit new_publication_path

    fill_in "Title", with: "Manual Title"
    fill_in "openalex-doi-input", with: "10.1234/invalid.doi"

    click_on "Search & Autofill"

    assert_text "Publication not found. Please check the DOI and try again."
    assert_field "Title", with: "Manual Title"
  end
end
