require "test_helper"

class AuthorTest < ActiveSupport::TestCase
  fixtures :authors, :publications, :publication_authorships

  test "person is valid with first and last name" do
    assert authors(:person).valid?
  end

  test "collective is valid with only collective name" do
    assert authors(:collective).valid?
  end

  test "person is invalid without first name" do
    author = Author.new(author_type: "person", last_name: "Kowalski")
    assert_not author.valid?
    assert_includes author.errors[:first_name], "can't be blank"
  end

  test "person is invalid without last name" do
    author = Author.new(author_type: "person", first_name: "Jan")
    assert_not author.valid?
    assert_includes author.errors[:last_name], "can't be blank"
  end

  test "person is invalid with collective name" do
    author = Author.new(
      author_type: "person",
      first_name: "Jan",
      last_name: "Kowalski",
      collective_name: "Lab Team"
    )
    assert_not author.valid?
    assert_includes author.errors[:collective_name], "must be blank"
  end

  test "collective is invalid without collective name" do
    author = Author.new(author_type: "collective")

    assert_not author.valid?
    assert_includes author.errors[:collective_name], "can't be blank"
  end

  test "collective is invalid with person fields" do
    author = Author.new(
      author_type: "collective",
      collective_name: "Lab Team",
      first_name: "Jan"
    )

    assert_not author.valid?
    assert_includes author.errors[:first_name], "must be blank"
  end

  test "invalid when author_type is not included in the list" do
    author = Author.new(
      author_type: "unknown",
      first_name: "Jan",
      last_name: "Kowalski"
    )

    assert_not author.valid?
    assert_includes author.errors[:author_type], "is not included in the list"
  end

  test "display name for person" do
    assert_equal "Dr. John Doe", authors(:person).display_name
  end

  test "display name for collective" do
    assert_equal "Test Team", authors(:collective).display_name
  end

    test "person? and collective? reflect inferred type from stored fields" do
    assert authors(:person).person?
    assert_not authors(:person).collective?

    assert authors(:collective).collective?
    assert_not authors(:collective).person?
  end

  test "normalize_author_fields converts blank strings to nil" do
    author = Author.new(
      author_type: "person",
      title: "",
      first_name: "Jan",
      last_name: "Kowalski",
      collective_name: ""
    )

    author.valid?

    assert_nil author.title
    assert_nil author.collective_name
  end

  test "name_search finds by cropped first name case insensitive" do
    result = Author.name_search("joh")

    assert_includes result, authors(:person)
    assert_not_includes result, authors(:collective)
  end

  test "name_search finds by cropped collective name" do
    result = Author.name_search("tes")

    assert_includes result, authors(:collective)
    assert_not_includes result, authors(:person)
  end

  test "name_search ignores accents" do
    accent_author = Author.create!(
      author_type: "person",
      first_name: "José",
      last_name: "Alvarez"
    )

    result = Author.name_search("jose")
    assert_includes result, accent_author
  end

  test "author_type_filter returns only person authors" do
    result = Author.author_type_filter("person")
    assert_includes result, authors(:person)
    assert_not_includes result, authors(:collective)
  end

  test "author_type_filter returns only collective authors" do
    result = Author.author_type_filter("collective")
    assert_includes result, authors(:collective)
    assert_not_includes result, authors(:person)
  end

  test "author_type_filter returns all for blank type" do
    result = Author.author_type_filter("")
    assert_includes result, authors(:person)
    assert_includes result, authors(:collective)
  end

  test "publications_count falls back to associated publications count" do
    author = authors(:person)
    assert_equal author.publications.size, author.publications_count
  end

  test "publications_count uses selected alias when present" do
    author = Author
      .left_joins(:publication_authorships)
      .select("authors.*, COUNT(DISTINCT publication_authorships.publication_id) AS publications_count")
      .group("authors.id")
      .find(authors(:person).id)

    assert_equal author.publications.size, author.publications_count
  end
end
