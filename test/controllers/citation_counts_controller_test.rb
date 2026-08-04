require "test_helper"

class CitationCountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @moderator = users(:moderator)
    @regular_user = users(:user)
    @citation_count = citation_counts(:openalex15)
  end

  test "regular user cannot delete citation count" do
    sign_in @regular_user

    assert_no_difference("CitationCount.count") do
      delete citation_count_url(@citation_count)
    end

    assert_redirected_to root_path
  end

  test "moderator can delete citation count via turbo stream" do
    sign_in @moderator

    assert_difference("CitationCount.count", -1) do
      delete citation_count_url(@citation_count), as: :turbo_stream
    end

    assert_response :success
    assert_match /turbo-stream action="remove"/, @response.body
  end
end
