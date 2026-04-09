require "test_helper"

class AuthorsFlowTest < ActionDispatch::IntegrationTest
  test "GET /authors opens successfully" do
    get authors_path

    assert_response :success
    assert_includes response.body, "Authors"
    assert_includes response.body, authors(:person).display_name
    assert_includes response.body, authors(:collective).display_name
  end

  test "search by name_search works" do
    get authors_path, params: { q: { name_search: "john" } }

    assert_response :success
    assert_includes response.body, authors(:person).display_name
    assert_not_includes response.body, authors(:collective).display_name
  end

  test "filter by author_type_filter works" do
    get authors_path, params: { q: { author_type_filter: "collective" } }

    assert_response :success
    assert_includes response.body, authors(:collective).display_name
    assert_not_includes response.body, authors(:person).display_name
  end

  test "GET /authors/:id shows author and all their publications" do
    author = authors(:person)
    get author_path(author)

    assert_response :success
    assert_includes response.body, authors(:person).display_name

    author.publications.each do |publication|
      assert_select "a[href='#{publication_path(publication)}']", text: publication.title
    end
  end

  test "unauthenticated user cannot merge authors" do
    source = authors(:person)
    target = authors(:collective)

    post merge_author_path(source), params: { target_author_id: target.id }

    assert_redirected_to new_user_session_path
  end

  test "non-moderator cannot merge authors" do
    sign_in users(:user)

    source = authors(:person)
    target = authors(:collective)

    post merge_author_path(source), params: { target_author_id: target.id }

    assert_redirected_to author_path(source)
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "moderator can merge authors and move all authorships to target author" do
    sign_in users(:moderator)

    source = authors(:person)
    target = authors(:collective)

    source_authorship_ids = source.publication_authorships.pluck(:id)
    source_publication_ids = source.publication_authorships.pluck(:publication_id)
    moved_count = source.publication_authorships.count

    assert_operator moved_count, :>, 0

    assert_difference("Author.count", -1) do
      post merge_author_path(source), params: { target_author_id: target.id }
    end

    assert_redirected_to author_path(target)
    assert_equal "Authorships were successfully moved.", flash[:notice]

    assert_raises(ActiveRecord::RecordNotFound) do
      source.reload
    end

    assert_empty PublicationAuthorship.where(author_id: source.id)

    source_publication_ids.each do |publication_id|
      assert PublicationAuthorship.exists?(publication_id: publication_id, author_id: target.id),
             "expected target author to be linked to publication #{publication_id}"
    end
  end
end
