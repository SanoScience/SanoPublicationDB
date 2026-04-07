require "test_helper"

class PublicationAuthorRulesTest < ActiveSupport::TestCase
  fixtures :authors, :publications, :publication_authorships

  def build_publication_for_ui
    publication = Publication.new(
      title: "Test publication",
      category: :journal_article,
      status: :submitted,
      author_list: "John Doe",
      publication_year: Time.zone.today.year,
      link: "https://example.com"
    )

    publication.build_kpi_reporting_extension(
        is_new_method_technique: true,
        is_methodology_application: true,
        is_polish_med_researcher_involved: true,
        is_co_publication_with_partners: true,
        is_peer_reviewed: true
    )
    publication
  end

  test "is valid in ui context with unique positions and unique authors" do
    publication = build_publication_for_ui
    publication.publication_authorships.build(
      author: authors(:person),
      position: 1
    )

    publication.publication_authorships.build(
      author: authors(:collective),
      position: 2
    )

    assert publication.valid?(:ui)
  end

  test "is invalid in ui context when positions are duplicated" do
    publication = build_publication_for_ui
    publication.publication_authorships.build(
      author: authors(:person),
      position: 1
    )

    publication.publication_authorships.build(
      author: authors(:collective),
      position: 1
    )

    assert_not publication.valid?(:ui)
    assert_includes publication.errors[:base], "Author positions must be unique"
  end

  test "is invalid in ui context when existing authors are duplicated" do
    publication = build_publication_for_ui
    publication.publication_authorships.build(
      author: authors(:person),
      position: 1
    )

    publication.publication_authorships.build(
      author: authors(:person),
      position: 2
    )

    assert_not publication.valid?(:ui)
    assert_includes publication.errors[:base], "Authors must be unique within one publication"
  end

  test "is invalid in ui context when new collective authors are duplicated" do
    publication = build_publication_for_ui
    authorship1 = publication.publication_authorships.build(position: 1)
    authorship1.build_author(
      author_type: "collective",
      collective_name: "Test Team"
    )

    authorship2 = publication.publication_authorships.build(position: 2)
    authorship2.build_author(
      author_type: "collective",
      collective_name: " test team "
    )

    assert_not publication.valid?(:ui)
    assert_includes publication.errors[:base], "Authors must be unique within one publication"
  end

  test "is invalid in ui context when new person authors are duplicated" do
    publication = build_publication_for_ui
    authorship1 = publication.publication_authorships.build(position: 1)
    authorship1.build_author(
      author_type: "person",
      title: "Dr.",
      first_name: "John",
      last_name: "Doe"
    )

    authorship2 = publication.publication_authorships.build(position: 2)
    authorship2.build_author(
      author_type: "person",
      title: " dr. ",
      first_name: " john ",
      last_name: " doe "
    )

    assert_not publication.valid?(:ui)
    assert_includes publication.errors[:base], "Authors must be unique within one publication"
  end

  test "reordered positions remain valid when final set is unique" do
    publication = build_publication_for_ui
    publication.publication_authorships.build(
      author: authors(:person),
      position: 2
    )

    publication.publication_authorships.build(
      author: authors(:collective),
      position: 1
    )

    assert publication.valid?(:ui)
  end
end
