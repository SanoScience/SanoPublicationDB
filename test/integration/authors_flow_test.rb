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
end