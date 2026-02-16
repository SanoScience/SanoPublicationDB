require "application_system_test_case"

class PublicationsJournalIssueSystemTest < ApplicationSystemTestCase
  include PublicationsJournalIssueSystemHelper, SystemTestsHelper

  def setup
    @user = users(:user)
    @moderator = users(:moderator)

    @jour1 = journal_issues(:jour1)
    @jour2 = journal_issues(:jour2)

    @pub_with_jour = publications(:pub1)
    @pub_no_jour   = publications(:pub_no_conf_jour)
  end

  test "regular user selecting journal issue in new shows fields (no delete toggle)" do
    sign_in @user
    visit new_publication_path

    select_journal_issue(@jour1.title)
    assert_journal_issue_fields(title: @jour1.title)

    within_journal_issue do
      assert_no_selector ".association-destroy-toggle", visible: :all
    end
  end

  test "switching selected journal issue in edit updates fields" do
    sign_in @user
    visit edit_publication_path(@pub_with_jour)

    assert_journal_issue_fields(title: @jour1.title)

    select_journal_issue(@jour2.title)
    assert_journal_issue_fields(title: @jour2.title)
  end

    test "moderator delete toggle in edit disables fields and cancel restores" do
    sign_in @moderator
    visit edit_publication_path(@pub_with_jour)

    within_journal_issue do
      find("button.association-destroy-toggle", text: "Delete").click

      assert_button "Cancel"
      assert_selector ".items-list select[disabled]"
      assert_field "Title", disabled: true

      find("button.association-destroy-toggle", text: "Cancel").click

      assert_button "Delete"
      assert_selector ".items-list select:not([disabled])"
      assert_field "Title", disabled: false
    end
  end

  test "selecting journal issue on publication with no initial journal issue in edit shows fields immediately" do
    sign_in @user
    visit edit_publication_path(@pub_no_jour)

    select_journal_issue(@jour1.title)
    assert_journal_issue_fields(title: @jour1.title)
  end

  test "add new journal issue in edit then cocoon delete returns select; update doesn't delete selected journal issue" do
    sign_in @user
    visit edit_publication_path(@pub_with_jour)

    within_journal_issue do
      click_on "Add New Journal Issue"
      assert_selector ".nested-fields", visible: true

      within ".nested-fields" do
        click_on "Delete"
      end

      assert_selector ".items-list", visible: true
      assert_no_selector ".nested-fields"
    end

    ensure_required_kpi_selected!
    click_on "Update Publication"
    assert_text "Publication was successfully updated."

    assert JournalIssue.exists?(@jour1.id)
    assert_equal @jour1.id, @pub_with_jour.reload.journal_issue_id
  end

  test "add new journal issue in edit, fill fields, update creates and links journal issue" do
    sign_in @user
    visit edit_publication_path(@pub_no_jour)

    before_count = JournalIssue.count

    within_journal_issue do
      click_on "Add New Journal Issue"
      assert_selector ".nested-fields", visible: true

      within ".nested-fields" do
        fill_in "Title", with: "Created From System Test"
      end
    end

    ensure_required_kpi_selected!
    click_on "Update Publication"
    assert_text "Publication was successfully updated."

    assert_equal before_count + 1, JournalIssue.count
    pub = @pub_no_jour.reload
    assert_not_nil pub.journal_issue_id
    assert_equal "Created From System Test", pub.journal_issue.title
  end
end
