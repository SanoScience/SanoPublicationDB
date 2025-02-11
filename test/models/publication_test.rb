require "test_helper"

class PublicationTest < ActiveSupport::TestCase
  fixtures :publications, :identifiers

  def setup
    @publication = publications("pub1")
  end

  test "should be validated and save" do
    assert @publication.valid? "Publication with valid attributes should be valid"
    assert @publication.save, "Publication should be saved successfully"
  end

  test "should require a title" do
    @publication.title = nil
    assert_not @publication.valid?
  end

  test "should require a valid link" do
    @publication.link = "invalid_url"
    assert_not @publication.valid?
  end

  test "should require a category from the list" do
    error = assert_raises(ArgumentError) do
      @publication.category = Publication.categories.values.last + 1
    end
    assert_match /is not a valid category/, error.message
  end  

  test "should require a status from the list" do
    error = assert_raises(ArgumentError) do
      @publication.status = Publication.statuses.values.last + 1
    end
    assert_match /is not a valid status/, error.message
  end  

  test "should be referenced in associated identifier" do
    identifier = @publication.identifiers.create(category: Identifier.categories.first.first, value: "test")

    assert_equal @publication.id, identifier.publication_id
  end

  test "should be referenced in associated repository link" do
    repository_link = @publication.repository_links.create(repository: RepositoryLink.repositories.first.first, value: "test")

    assert_equal @publication.id, repository_link.publication_id
  end

  test "should be referenced in associated research group publication" do
    research_group_publication = 
      @publication.research_group_publications.create(
        research_group: ResearchGroupPublication.research_groups.first.first, 
        is_primary: true
      )

    assert_equal @publication.id, research_group_publication.publication_id
  end
end
