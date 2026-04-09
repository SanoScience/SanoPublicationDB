require "test_helper"

class AuthorsAuthorizationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "guest cannot open edit" do
    get edit_author_path(authors(:person))

    assert_response :redirect
  end

  test "regular user cannot open edit" do
    sign_in users(:user)

    get edit_author_path(authors(:person))

    assert_response :redirect
    assert_redirected_to author_path(authors(:person))
  end

  test "regular user cannot update author" do
    sign_in users(:user)

    patch author_path(authors(:person)), params: {
      author: {
        author_type: "person",
        first_name: "Jack",
        last_name: "Doe"
      }
    }

    assert_response :redirect
    assert_redirected_to author_path(authors(:person))
    assert_equal "John", authors(:person).reload.first_name
  end

  test "regular user cannot destroy author" do
    sign_in users(:user)

    assert_no_difference("Author.count") do
      delete author_path(authors(:person))
    end

    assert_response :redirect
    assert_redirected_to author_path(authors(:person))
  end

  test "moderator can open edit" do
    sign_in users(:moderator)

    get edit_author_path(authors(:person))

    assert_response :success
  end

  test "moderator can update author" do
    sign_in users(:moderator)
    author = authors(:person)
    publication = publications(:pub1)

    assert_includes publication.reload.formatted_authors, "John"

    patch author_path(author), params: {
        author: {
            author_type: "person",
            title: "Dr.",
            first_name: "Jack",
            last_name: "Doe"
        }
    }

    assert_response :redirect
    assert_redirected_to author_path(author)
    assert_equal "Jack", author.reload.first_name
    assert_equal "Dr. Jack Doe", author.display_name
    assert_includes publication.reload.formatted_authors, "Jack"
    assert_not_includes publication.reload.formatted_authors, "John Doe"
  end

  test "moderator destroys author and removes related authorships" do
    sign_in users(:moderator)

    author = authors(:person)
    publication = publications(:pub1)
    authorship = publication_authorships(:person_pub1_authorship)

    removed_authorships_count = author.publication_authorships.count

    assert_includes publication.reload.authors, author

    assert_difference("Author.count", -1) do
        assert_difference("PublicationAuthorship.count", -removed_authorships_count) do
            delete author_path(author)
        end
    end

    assert_redirected_to authors_path
    assert_nil PublicationAuthorship.find_by(id: authorship.id)
    assert_empty PublicationAuthorship.where(author_id: author.id)
    assert_not_includes publication.reload.authors, author

    assert_raises(ActiveRecord::RecordNotFound) do
        author.reload
    end
  end
end
