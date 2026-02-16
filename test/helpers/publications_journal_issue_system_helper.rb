module PublicationsJournalIssueSystemHelper
  def within_journal_issue
    within ".journal-issue" do
      yield
    end
  end

  def select_journal_issue(title)
    within_journal_issue do
      find(".items-list select").select(title)
    end
  end

  def assert_journal_issue_fields(title:)
    within_journal_issue do
      assert_field "Title", with: title
    end
  end
end
