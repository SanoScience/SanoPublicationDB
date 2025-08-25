require "test_helper"

class ResearchGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @moderator = users(:moderator)
    @research_group = research_groups(:group1)
  end

  test "should redirect index when not logged in" do
    get research_groups_path
    assert_redirected_to new_user_session_path
  end

  test "moderator should get index" do
    sign_in @moderator
    get research_groups_path
    assert_response :success
    assert_select "h1", /Research Groups/
  end

  test "moderator should create research group" do
    sign_in @moderator
    assert_difference("ResearchGroup.count") do
      post research_groups_path, params: { research_group: { name: "New Group", description: "Test desc" } }
    end
    assert_redirected_to research_groups_path
  end

  test "moderator should update research group" do
    sign_in @moderator
    patch research_group_path(@research_group), params: { research_group: { name: "Updated name" } }
    assert_redirected_to research_groups_path
    @research_group.reload
    assert_equal "Updated name", @research_group.name
  end

  test "moderator should NOT destroy research group if it has publications" do
    sign_in @moderator
    assert_no_difference("ResearchGroup.count") do
      delete research_group_path(@research_group)
    end
    assert_redirected_to research_groups_path
    assert_equal "Cannot delete record because dependent research group publications exist", flash[:alert]
  end

  test "moderator should destroy research group without publications" do
    sign_in @moderator
    deletable = ResearchGroup.create!(name: "Temp deletable")

    assert_difference("ResearchGroup.count", -1) do
      delete research_group_path(deletable)
    end
    assert_redirected_to research_groups_path
  end
end
