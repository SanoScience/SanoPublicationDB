require "test_helper"

class PublicationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get publications_path
    assert_response :success
  end

  test "authenticated user should get new" do
    sign_in users(:user)
    get new_publication_path
    assert_response :success
  end

  test "unauthenticated user should not get new" do
    get new_publication_path
    assert_redirected_to new_user_session_path
  end

  test "authenticated user should create publication" do
    sign_in users(:user)

    assert_difference("Publication.count", 1) do
      post publications_path, params: {
        publication: {
          title:  "Test publication",
          category: "journal_article",
          status: "submitted",
          author_list: "John Doe, Jane Smith",
          publication_year: Time.zone.today.year,
          kpi_reporting_extension_attributes: {
            is_new_method_technique: false,
            is_methodology_application: false,
            is_polish_med_researcher_involved: false,
            is_peer_reviewed: false,
            is_co_publication_with_partners: false
          }
        }
      }, xhr: true
    end

    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_equal users(:user), Publication.last.owner
  end

  test "unauthenticated user should not create publication" do
    assert_no_difference("Publication.count") do
      post publications_path, params: {
        publication: {
          title: "Test publication",
          category: "journal_article",
          status: "submitted",
          author_list: "John Doe, Jane Smith" }
      }, xhr: true
    end

    assert_response :unauthorized
  end

  test "should get show" do
    get publication_path(publications("pub1"))
    assert_response :success
  end

  test "authenticated owner should get edit" do
    sign_in users(:user)
    get edit_publication_path(publications("pub1"))
    assert_response :success
  end

  test "unauthenticated user should not get edit" do
    get edit_publication_path(publications("pub1"))
    assert_redirected_to new_user_session_path
  end

  test "authenticated not owner should not get edit" do
    sign_in users(:user2)
    get edit_publication_path(publications("pub1"))
    assert_redirected_to publication_path(publications("pub1"))
  end

  test "authenticated owner should update publication" do
    sign_in users(:user)
    publication = publications(:pub1)

    assert_changes -> { publication.reload.title } do
      patch publication_path(publication), params: {
        publication: { title: "Updated publication" }
      }
    end

    assert_redirected_to publication_path(publication)
  end

  test "unauthenticated user should not update publication" do
    publication = publications(:pub1)

    assert_no_changes -> { publication.reload.title } do
      patch publication_path(publication), params: {
        publication: { title: "Updated publication" }
      }, xhr: true
    end

    assert_response :unauthorized
  end

  test "authenticated not owner should not update publication" do
    sign_in users(:user2)
    publication = publications(:pub1)

    assert_no_changes -> { publication.reload.title } do
      patch publication_path(publication), params: {
        publication: { title: "Updated publication" }
      }
    end

    assert_redirected_to publication_path(publication)
  end

  test "authenticated owner should destroy publication" do
    sign_in users(:user)
    publication = publications(:pub1)

    assert_changes -> { Publication.count }, -1 do
      delete publication_path(publication), xhr: true
    end

    assert_redirected_to publications_path
  end

  test "unauthenticated user should not destroy publication" do
    assert_no_changes -> { Publication.count } do
      delete publication_path(publications("pub1")), xhr: true
    end

    assert_response :unauthorized
  end

  test "authenticated not owner should not destroy publication" do
    sign_in users(:user2)

    assert_no_changes -> { Publication.count } do
      delete publication_path(publications("pub1")), xhr: true
    end

    assert_redirected_to publication_path(publications("pub1"))
  end
end
