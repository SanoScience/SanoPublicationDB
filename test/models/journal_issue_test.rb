require "test_helper"

class JournalIssueTest < ActiveSupport::TestCase
  def setup
    @journal_issue = journal_issues("jour1")
  end

  test "should be validated and saved" do
    assert @journal_issue.valid?
    assert @journal_issue.save
  end

  test "should require a title" do
    @journal_issue.title = nil
    assert_not @journal_issue.valid?
    assert_includes @journal_issue.errors[:title], "can't be blank"
  end

  test "should nullify references in publications if deleted" do
    publication = publications("pub1")
    assert_equal @journal_issue.id, publication.journal_issue_id do
      @journal_issue.destroy

      assert_not_nil publication do
        assert_nil publication.reload.journal_issue_id
      end
    end
  end
end
