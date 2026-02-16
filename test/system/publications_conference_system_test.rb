require "application_system_test_case"

class PublicationsConferenceSystemTest < ApplicationSystemTestCase
  include PublicationsConferenceSystemHelper, SystemTestsHelper

  def setup
    @user = users(:user)
    @moderator = users(:moderator)

    @conf1 = conferences(:conf1)
    @conf2 = conferences(:conf2)

    @pub_with_conf = publications(:pub1)
    @pub_no_conf = publications(:pub_no_conf_jour)
  end

  test "regular user selecting conference in new shows fields, no delete toggle" do
    sign_in @user
    visit new_publication_path

    select_conference(@conf1.name)
    assert_conf_fields(name: @conf1.name, core: @conf1.core)

    within_conference do
      assert_no_selector ".association-destroy-toggle", visible: :all
    end
  end

  test "moderator selecting conference in new shows fields, delete toggle hidden" do
    sign_in @moderator
    visit new_publication_path

    select_conference(@conf1.name)
    assert_conf_fields(name: @conf1.name, core: @conf1.core)

    within_conference do
      assert_selector ".association-destroy-toggle", visible: false
    end
  end

  test "switching selected conference in edit updates fields and hides delete toggle" do
    sign_in @moderator
    visit edit_publication_path(@pub_with_conf)

    assert_conf_fields(name: @conf1.name, core: @conf1.core)

    select_conference(@conf2.name)
    assert_conf_fields(name: @conf2.name, core: @conf2.core)

    within_conference do
      assert_selector ".association-destroy-toggle", visible: false
    end
  end

  test "selecting conference on publication with no initial conference in edit shows fields immediately" do
    sign_in @moderator
    visit edit_publication_path(@pub_no_conf)

    select_conference(@conf1.name)
    assert_conf_fields(name: @conf1.name, core: @conf1.core)

    within_conference do
      assert_selector ".association-destroy-toggle", visible: false
    end
  end

  test "moderator delete toggle in edit disables fields and cancel restores" do
    sign_in @moderator
    visit edit_publication_path(@pub_with_conf)

    within_conference do
      find("button.association-destroy-toggle", text: "Delete").click
      assert_button "Cancel"
      assert_selector ".items-list select[disabled]"
      assert_field "Conference Name", disabled: true

      find("button.association-destroy-toggle", text: "Cancel").click
      assert_button "Delete"
      assert_selector ".items-list select:not([disabled])"
      assert_field "Conference Name", disabled: false
    end
  end

  test "add new conference in edit then cocoon delete returns select; update doesn't delete selected conference" do
    sign_in @user
    visit edit_publication_path(@pub_with_conf)

    within_conference do
      click_on "Add New Conference"
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

    assert Conference.exists?(@conf1.id)
    assert_equal @conf1.id, @pub_with_conf.reload.conference_id
  end

  test "add new conference in edit, fill fields, update creates and links conference" do
    sign_in @user
    visit edit_publication_path(@pub_no_conf)

    before_count = Conference.count

    within_conference do
      click_on "Add New Conference"
      assert_selector ".nested-fields", visible: true

      within ".nested-fields" do
        fill_in "Conference Name", with: "Created From System Test"
        fill_in "CORE Ranking", with: "A"

        set_date_select("start_date", year: 2025, month_name: "January", day: 10)
        set_date_select("end_date",   year: 2025, month_name: "January", day: 12)
      end
    end

    ensure_required_kpi_selected!
    click_on "Update Publication"
    assert_text "Publication was successfully updated."

    assert_equal before_count + 1, Conference.count
    pub = @pub_no_conf.reload
    assert_not_nil pub.conference_id
    assert_equal "Created From System Test", pub.conference.name
  end
end
