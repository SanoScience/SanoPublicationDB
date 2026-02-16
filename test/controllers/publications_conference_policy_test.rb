require "test_helper"

class PublicationsConferencePolicyTest < ActionDispatch::IntegrationTest
    test "unlinking conference from publication does not delete conference" do
        sign_in users(:user)
        publication = publications(:pub1)
        conference  = conferences(:conf1)

        assert_equal conference.id, publication.conference_id

        assert_no_difference("Conference.count") do
            patch publication_path(publication), params: {
                publication: { conference_id: "" } # include_blank -> ""
            }
        end

        assert_nil publication.reload.conference_id
        assert Conference.exists?(conference.id)
    end

    test "non-moderator cannot delete conference" do
        sign_in users(:user)
        publication = publications(:pub1)
        conference  = conferences(:conf1)

        assert_equal conference.id, publication.conference_id

        assert_no_difference("Conference.count") do
            patch publication_path(publication), params: {
                publication: {
                    conference_attributes: { id: conference.id, _destroy: "1" }
                }
            }
        end

        assert Conference.exists?(conference.id)
        assert_equal conference.id, publication.reload.conference_id
    end

    test "moderator can delete currently associated conference" do
        sign_in users(:moderator)
        publication = publications(:pub1)
        conference  = conferences(:conf1)

        assert_equal conference.id, publication.conference_id

        assert_difference("Conference.count", -1) do
            patch publication_path(publication), params: {
                publication: {
                    conference_attributes: { id: conference.id, _destroy: "1" }
                }
            }
        end

        assert_not Conference.exists?(conference.id)
        assert_nil publication.reload.conference_id
    end

    test "moderator cannot delete conference not currently associated with publication" do
        sign_in users(:moderator)
        publication = publications(:pub1)
        conf1 = conferences(:conf1)
        conf2 = Conference.create!(
            name: "Other Conf", core: "B",
            start_date: Date.new(2025, 1, 1),
            end_date: Date.new(2025, 1, 2)
        )

        assert_equal conf1.id, publication.conference_id

        assert_no_difference("Conference.count") do
            patch publication_path(publication), params: {
                publication: {
                    conference_attributes: { id: conf2.id, _destroy: "1" }
                }
            }
        end

        assert Conference.exists?(conf2.id)
        assert_equal conf1.id, publication.reload.conference_id
    end

    test "authenticated user can select and edit conference fields while creating publication" do
        sign_in users(:user)
        conference = conferences(:conf1)

        assert_difference("Publication.count", 1) do
            post publications_path, params: {
                publication: {
                    title: "Pub with edited conf",
                    category: "journal_article",
                    status: "submitted",
                    author_list: "John Doe",
                    publication_year: Time.zone.today.year,
                    conference_id: conference.id,
                    conference_attributes: {
                    id: conference.id,
                    name: "Renamed Conference",
                    core: "A",
                    start_date: "2012-12-12",
                    end_date: "2012-12-15"
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

        assert_equal conference.id, Publication.last.conference_id
        assert_equal "Renamed Conference", conference.reload.name
    end

    test "authenticated user can link and edit conference fields in one update" do
        sign_in users(:user)
        publication = publications(:pub_no_conf_jour)
        conference  = conferences(:conf1)

        patch publication_path(publication), params: {
            publication: {
                conference_id: conference.id,
                conference_attributes: {
                    id: conference.id,
                    name: "Edited from edit form"
                }
            }
        }

        assert_equal conference.id, publication.reload.conference_id
        assert_equal "Edited from edit form", conference.reload.name
    end

    test "authenticated user can create a new conference while creating publication" do
        sign_in users(:user)

        base_publication_params = {
            title: "Pub",
            category: "journal_article",
            status: "submitted",
            author_list: "John Doe",
            publication_year: Time.zone.today.year,
            kpi_reporting_extension_attributes: {
                is_new_method_technique: false,
                is_methodology_application: false,
                is_polish_med_researcher_involved: false,
                is_peer_reviewed: false,
                is_co_publication_with_partners: false
            }
        }

        assert_difference("Publication.count", 1) do
            assert_difference("Conference.count", 1) do
                post publications_path, params: {
                    publication: base_publication_params.merge(
                        conference_id: "",
                        conference_attributes: {
                        name: "Brand New Conf",
                        start_date: "2025-01-01",
                        end_date: "2025-01-02"
                        }
                    )
                }
            end
        end

        pub = Publication.order(:id).last
        assert_not_nil pub.conference_id
        assert_equal "Brand New Conf", pub.conference.name
    end

    test "authenticated user can create and link a new conference in one update" do
        sign_in users(:user)

        publication = publications(:pub_no_conf_jour)

        assert_difference("Conference.count", 1) do
            patch publication_path(publication), params: {
            publication: {
                conference_id: "",
                conference_attributes: {
                name: "Conf Created On Update",
                start_date: "2025-02-01",
                end_date: "2025-02-02"
                }
            }
            }
        end

        assert_redirected_to publication_path(publication)
        assert_equal "Conf Created On Update", publication.reload.conference.name
    end
end
