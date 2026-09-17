require "test_helper"

class NanasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nana = nanas(:one)
  end

  test "should get index" do
    get nanas_url
    assert_response :success
  end

  test "should get new" do
    get new_nana_url
    assert_response :success
  end

  test "should create nana" do
    assert_difference("Nana.count") do
      post nanas_url, params: { nana: { name: @nana.name, profile_image: @nana.profile_image } }
    end

    assert_redirected_to nana_url(Nana.last)
  end

  test "should show nana" do
    get nana_url(@nana)
    assert_response :success
  end

  test "should get edit" do
    get edit_nana_url(@nana)
    assert_response :success
  end

  test "should update nana" do
    patch nana_url(@nana), params: { nana: { name: @nana.name, profile_image: @nana.profile_image } }
    assert_redirected_to nana_url(@nana)
  end

  test "should destroy nana" do
    assert_difference("Nana.count", -1) do
      delete nana_url(@nana)
    end

    assert_redirected_to nanas_url
  end
end
