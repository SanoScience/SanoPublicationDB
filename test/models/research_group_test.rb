require "test_helper"

class ResearchGroupTest < ActiveSupport::TestCase
  def setup
    @group = research_groups(:group1)
  end

  test "should be valid with a name" do
    assert @group.valid?
  end

  test "should require a name" do
    @group.name = nil
    assert_not @group.valid?
    assert_includes @group.errors[:name], "can't be blank"
  end

  test "should enforce unique name" do
    duplicate = ResearchGroup.new(name: research_groups(:group1).name)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "should have many research group publications" do
    assert_respond_to @group, :research_group_publications
  end

  test "should have many publications through research group publications" do
    assert_respond_to @group, :publications
  end
end
