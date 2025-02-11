require "test_helper"

class RepositoryLinkTest < ActiveSupport::TestCase
  def setup
    @repository_link = repository_links("dataverse")
  end

  test "should be valid with all attributes present" do
    assert @repository_link.valid?
    assert @repository_link.save
  end

  test "should require a publication" do
    @repository_link.publication = nil
    assert_not @repository_link.valid?
    assert_includes @repository_link.errors[:publication], "can't be blank"
  end

  test "should require a repository" do
    @repository_link.repository = nil
    assert_not @repository_link.valid?
    assert_includes @repository_link.errors[:repository], "can't be blank"
  end

  test "should require a value" do
    @repository_link.value = nil
    assert_not @repository_link.valid?
    assert_includes @repository_link.errors[:value], "can't be blank"
  end

  test "should be destroyed when associated publication is destroyed" do
    publication = publications("pub1")
    publication.destroy
    
    assert_nil RepositoryLink.find_by(id: @repository_link.id)
  end
end
