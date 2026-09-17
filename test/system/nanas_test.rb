require "application_system_test_case"

class NanasTest < ApplicationSystemTestCase
  setup do
    @nana = nanas(:one)
  end

  test "visiting the index" do
    visit nanas_url
    assert_selector "h1", text: "Nanas"
  end

  test "should create nana" do
    visit nanas_url
    click_on "New nana"

    fill_in "Name", with: @nana.name
    fill_in "Profile image", with: @nana.profile_image
    click_on "Create Nana"

    assert_text "Nana was successfully created"
    click_on "Back"
  end

  test "should update Nana" do
    visit nana_url(@nana)
    click_on "Edit this nana", match: :first

    fill_in "Name", with: @nana.name
    fill_in "Profile image", with: @nana.profile_image
    click_on "Update Nana"

    assert_text "Nana was successfully updated"
    click_on "Back"
  end

  test "should destroy Nana" do
    visit nana_url(@nana)
    click_on "Destroy this nana", match: :first

    assert_text "Nana was successfully destroyed"
  end
end
