require "test_helper"

class PublicationAuthorshipTest < ActiveSupport::TestCase
  fixtures :authors, :publications, :publication_authorships

  test "fixture is valid" do
    assert publication_authorships(:person_pub1_authorship).valid?
  end

  test "belongs to publication and author" do
    authorship = publication_authorships(:person_pub1_authorship)
    assert_equal publications(:pub1), authorship.publication
    assert_equal authors(:person), authorship.author
    assert_equal 1, authorship.position
  end

  test "is invalid without publication" do
    authorship = PublicationAuthorship.new(
      author: authors(:person),
      position: 1
    )

    assert_not authorship.valid?
    assert_includes authorship.errors[:publication], "must exist"
  end

  test "is invalid without author" do
    authorship = PublicationAuthorship.new(
      publication: publications(:pub1),
      position: 1
    )

    assert_not authorship.valid?
    assert_includes authorship.errors[:author], "must be selected or created"
  end

  test "is invalid without position" do
    authorship = PublicationAuthorship.new(
      publication: publications(:pub1),
      author: authors(:person)
    )

    assert_not authorship.valid?
    assert_includes authorship.errors[:position], "can't be blank"
  end

  test "same author cannot be added twice to the same publication" do
    duplicate = PublicationAuthorship.new(
      publication: publications(:pub1),
      author: authors(:person),
      position: 2
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate.save!(validate: false)
    end
  end

  test "same position cannot be used twice in the same publication" do
    another_author = Author.create!(
      author_type: "person",
      first_name: "Jane",
      last_name: "Smith"
    )

    assert_raises(ActiveRecord::StatementInvalid) do
      PublicationAuthorship.transaction do
        PublicationAuthorship.connection.execute(
          "SET CONSTRAINTS publication_authorships_publication_id_position_key IMMEDIATE"
        )

        PublicationAuthorship.create!(
          publication: publications(:pub1),
          author: another_author,
          position: 1
        )
      end
    end
  end

  test "same author can be used in another publication" do
    authorship = PublicationAuthorship.new(
      publication: publications(:pub_no_conf_jour),
      author: authors(:person),
      position: 1
    )

    assert authorship.valid?
  end

  test "same position can be used in another publication" do
    another_author = Author.create!(
      author_type: "person",
      first_name: "Jane",
      last_name: "Smith"
    )

    authorship = PublicationAuthorship.new(
      publication: publications(:pub_no_conf_jour),
      author: another_author,
      position: 1
    )

    assert authorship.valid?
  end

  test "destroying authorship removes link between publication and author" do
    authorship = publication_authorships(:person_pub1_authorship)
    publication = authorship.publication
    author = authorship.author

    assert_includes publication.authors, author
    assert_difference("PublicationAuthorship.count", -1) do
      authorship.destroy
    end

    assert_not_includes publication.reload.authors, author
  end
end
