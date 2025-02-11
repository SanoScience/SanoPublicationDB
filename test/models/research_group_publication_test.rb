require "test_helper"

class ResearchGroupPublicationTest < ActiveSupport::TestCase
  def setup
    @research_group_publication = research_group_publications("sp_pub1")
  end

  test "should be valid with all attributes present" do
    assert @research_group_publication.valid?
    assert @research_group_publication.save
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

  test "should require is_primary" do
    @research_group_publication.is_primary = nil
    assert_not @research_group_publication.valid?
    assert_includes @research_group_publication.errors[:is_primary], "can't be blank"
  end

  test "should be destroyed when associated publication is destroyed" do
    publication = publications("pub1")
    publication.destroy
    
    assert_nil ResearchGroupPublication.find_by(id: @research_group_publication.id)
  end
end
