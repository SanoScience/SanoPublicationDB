require "test_helper"

class ConferenceTest < ActiveSupport::TestCase
  def setup
    @conference = conferences("conf1")
  end

  test "should be validated and saved" do
    assert @conference.valid?
    assert @conference.save
  end

  test "should require a name" do
    @conference.name = nil
    assert_not @conference.valid?
    assert_includes @conference.errors[:name], "can't be blank"
  end

  # test "should be invalid without start_date" do
  #   @conference.start_date = nil
  #   assert_not @conference.valid?
  #   assert_includes @conference.errors[:start_date], "can't be blank"
  # end

  # test "should be invalid without end_date" do
  #   @conference.end_date = nil
  #   assert_not @conference.valid?
  #   assert_includes @conference.errors[:end_date], "can't be blank"
  # end

  test "should be invalid with start_date after end_date" do
    @conference.start_date = Date.new(2025, 6, 15)
    @conference.end_date = Date.new(2025, 6, 10)

    assert_not @conference.valid?
    assert_includes @conference.errors[:end_date], "must be after start_date"
  end

  test "should nullify references in publications if deleted" do
    conference = conferences("conf1")
    publication = publications("pub1")

    assert_equal conference.id, publication.conference_id

    assert_difference("Conference.count", -1) do
      conference.destroy
    end

    assert_nil publication.reload.conference_id
  end
end
