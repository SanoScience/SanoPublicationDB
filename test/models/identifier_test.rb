require "test_helper"

class IdentifierTest < ActiveSupport::TestCase
  def setup
    @identifier = identifiers("doi")
  end

  test "should be validated and saved" do
    assert @identifier.valid?
    assert @identifier.save
  end

  test "should require a publication" do
    @identifier.publication = nil
    assert_not @identifier.valid?
    assert_includes @identifier.errors[:publication], "can't be blank"
  end

  test "should require a category" do
    @identifier.category = nil
    assert_not @identifier.valid?
    assert_includes @identifier.errors[:category], "can't be blank"
  end

  test "should require a value" do
    @identifier.value = nil
    assert_not @identifier.valid?
    assert_includes @identifier.errors[:value], "can't be blank"
  end

  test "should be destroyed when publication is destroyed" do
    publication = publications("pub1")
    assert_equal publication.id, @identifier.publication_id do
      publication.destroy
      
      assert_nil Identifier.find_by(id: @identifier.id)
    end
  end
end
