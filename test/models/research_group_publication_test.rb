require "test_helper"

class ResearchGroupPublicationTest < ActiveSupport::TestCase
  def setup
    @publication = publications(:pub1)
    @research_group = research_groups(:group1)

    @research_group_publication = ResearchGroupPublication.new(
      publication: @publication,
      research_group: @research_group,
      is_primary: true
    )
    @research_group_publication.save!
  end

  test "should be valid with all attributes present" do
    assert @research_group_publication.valid?
  end

  test "should require a publication" do
    @research_group_publication.publication = nil
    assert_not @research_group_publication.valid?
    assert_includes @research_group_publication.errors[:publication], "can't be blank"
  end

  test "should require a research_group" do
    @research_group_publication.research_group = nil
    assert_not @research_group_publication.valid?
    assert_includes @research_group_publication.errors[:research_group], "can't be blank"
  end

  test "should be destroyed when associated publication is destroyed" do
    publication = @research_group_publication.publication
    publication.destroy

    assert_not ResearchGroupPublication.exists?(@research_group_publication.id)
  end
end
