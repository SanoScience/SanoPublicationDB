require "test_helper"

class PublicationsJournalIssuePolicyTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    @moderator = users(:moderator)

    @pub_with_jour = publications(:pub1)
    @pub_no_jour = publications(:pub_no_conf_jour)

    @jour1 = journal_issues(:jour1)
    @jour2 = journal_issues(:jour2)
  end

  test "unlinking journal issue from publication does not delete journal issue" do
    sign_in @user
    assert_equal @jour1.id, @pub_with_jour.journal_issue_id

    assert_no_difference("JournalIssue.count") do
      patch publication_path(@pub_with_jour), params: {
        publication: { journal_issue_id: "" } # include_blank => ""
      }
    end

    assert_nil @pub_with_jour.reload.journal_issue_id
    assert JournalIssue.exists?(@jour1.id)
  end

  test "non-moderator cannot delete journal issue via nested _destroy" do
    sign_in @user
    assert_equal @jour1.id, @pub_with_jour.journal_issue_id

    assert_no_difference("JournalIssue.count") do
      patch publication_path(@pub_with_jour), params: {
        publication: {
          journal_issue_attributes: { id: @jour1.id, _destroy: "1" }
        }
      }
    end

    assert JournalIssue.exists?(@jour1.id)
    assert_equal @jour1.id, @pub_with_jour.reload.journal_issue_id
  end

  test "moderator can delete currently associated journal issue" do
    sign_in @moderator
    assert_equal @jour1.id, @pub_with_jour.journal_issue_id

    assert_difference("JournalIssue.count", -1) do
      patch publication_path(@pub_with_jour), params: {
        publication: {
          journal_issue_attributes: { id: @jour1.id, _destroy: "1" }
        }
      }
    end

    assert_not JournalIssue.exists?(@jour1.id)
    assert_nil @pub_with_jour.reload.journal_issue_id
  end

  test "moderator cannot delete journal issue that is NOT currently associated with publication" do
    sign_in @moderator
    assert_equal @jour1.id, @pub_with_jour.journal_issue_id
    assert JournalIssue.exists?(@jour2.id)

    assert_no_difference("JournalIssue.count") do
      patch publication_path(@pub_with_jour), params: {
        publication: {
          journal_issue_attributes: { id: @jour2.id, _destroy: "1" }
        }
      }
    end

    assert JournalIssue.exists?(@jour2.id)
    assert_equal @jour1.id, @pub_with_jour.reload.journal_issue_id
  end

  test "authenticated user can link and edit journal issue fields in one update" do
    sign_in @user
    assert_nil @pub_no_jour.journal_issue_id

    patch publication_path(@pub_no_jour), params: {
      publication: {
        journal_issue_id: @jour1.id,
        journal_issue_attributes: {
          id: @jour1.id,
          title: "Edited from edit form"
        }
      }
    }

    assert_equal @jour1.id, @pub_no_jour.reload.journal_issue_id
    assert_equal "Edited from edit form", @jour1.reload.title
  end

  test "authenticated user can select and edit journal issue fields while creating publication" do
    sign_in @user

    assert_difference("Publication.count", 1) do
      post publications_path, params: {
        publication: {
          title: "Pub with edited journal issue",
          category: "journal_article",
          status: "submitted",
          author_list: "John Doe",
          publication_year: Time.zone.today.year,

          journal_issue_id: @jour1.id,
          journal_issue_attributes: {
            id: @jour1.id,
            title: "Renamed Journal Issue"
          },

          kpi_reporting_extension_attributes: {
            is_new_method_technique: false,
            is_methodology_application: false,
            is_polish_med_researcher_involved: false,
            is_peer_reviewed: false,
            is_co_publication_with_partners: false
          }
        }
      }
    end

    pub = Publication.order(:id).last
    assert_equal @jour1.id, pub.journal_issue_id
    assert_equal "Renamed Journal Issue", @jour1.reload.title
  end

  test "authenticated user can create a new journal issue while creating publication" do
    sign_in @user

    assert_difference("Publication.count", 1) do
      assert_difference("JournalIssue.count", 1) do
        post publications_path, params: {
          publication: {
            title: "Pub with new journal issue",
            category: "journal_article",
            status: "submitted",
            author_list: "John Doe",
            publication_year: Time.zone.today.year,

            journal_issue_id: "",
            journal_issue_attributes: {
              title: "Brand New Journal Issue",
              journal_num: "Vol 10",
              publisher: "AGH",
              volume: 10,
              impact_factor: 12.0
            },

            kpi_reporting_extension_attributes: {
              is_new_method_technique: false,
              is_methodology_application: false,
              is_polish_med_researcher_involved: false,
              is_peer_reviewed: false,
              is_co_publication_with_partners: false
            }
          }
        }
      end
    end

    pub = Publication.order(:id).last
    assert_not_nil pub.journal_issue_id
    assert_equal "Brand New Journal Issue", pub.journal_issue.title
  end

  test "authenticated user can create and link a new journal issue in one update" do
    sign_in @user
    assert_nil @pub_no_jour.journal_issue_id

    assert_difference("JournalIssue.count", 1) do
      patch publication_path(@pub_no_jour), params: {
        publication: {
          journal_issue_id: "",
          journal_issue_attributes: {
            title: "Journal Issue Created On Update",
            journal_num: "Vol 11",
            publisher: "AGH",
            volume: 11,
            impact_factor: 9.5
          }
        }
      }
    end

    assert_redirected_to publication_path(@pub_no_jour)
    assert_equal "Journal Issue Created On Update", @pub_no_jour.reload.journal_issue.title
  end
end
