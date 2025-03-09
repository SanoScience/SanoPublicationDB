require "test_helper"

class PublicationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get publications_path
    assert_response :success
  end

  test "should get new" do
    get new_publication_path
    assert_response :success
  end

  test "should get create" do
    get new_publication_path, xhr: true
    assert_response :success
  end

  test "should get show" do
    get publication_path(publications("pub1"))
    assert_response :success
  end

  test "should get edit" do
    get edit_publication_path(publications("pub1"))
    assert_response :success
  end

  test "should get update" do
    get edit_publication_path(publications("pub1")), xhr: true
    assert_response :success
  end

  test "should get destroy" do
    get publication_path(publications("pub1")), xhr: true
    assert_response :success
  end
end
