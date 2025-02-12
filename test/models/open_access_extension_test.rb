require "test_helper"

class OpenAccessExtensionTest < ActiveSupport::TestCase
  def setup
    @open_access_extension = open_access_extensions("green")
  end

  test "should be valid with a publication and category" do
    assert @open_access_extension.valid?
    assert @open_access_extension.save
  end

  test "should require a publication" do
    @open_access_extension.publication = nil
    assert_not @open_access_extension.valid?
    assert_includes @open_access_extension.errors[:publication], "can't be blank"
  end

  test "should require a category" do
    @open_access_extension.category = nil
    assert_not @open_access_extension.valid?
    assert_includes @open_access_extension.errors[:category], "can't be blank"
  end

  test "should validate inclusion of category" do
    error = assert_raises(ArgumentError) do
      @open_access_extension.category = OpenAccessExtension.categories.values.last + 1
    end
    assert_match /is not a valid category/, error.message
  end

  test "should not allow gold OA fields for green OA" do
    @open_access_extension.category = :green
    @open_access_extension.gold_oa_charges = 1.0
    @open_access_extension.gold_oa_funding_source = "Some source"

    assert_not @open_access_extension.valid?
    assert_includes @open_access_extension.errors[:gold_oa_charges], "should be empty for green OA"
    assert_includes @open_access_extension.errors[:gold_oa_funding_source], "should be empty for green OA"
  end

  test "should be valid with gold OA and gold OA fields populated" do
    @open_access_extension.category = :gold
    @open_access_extension.gold_oa_charges = 1.0
    @open_access_extension.gold_oa_funding_source = "Some source"

    assert @open_access_extension.valid?
  end

  test "should be destroyed when associated publication is destroyed" do
    publication = publications("pub1")
    publication.destroy

    assert_nil OpenAccessExtension.find_by(id: @open_access_extension.id)
  end
end
