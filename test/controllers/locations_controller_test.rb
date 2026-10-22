require "test_helper"

class LocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @location = locations(:one)
  end

  test "should get index" do
    get locations_url
    assert_response :success
  end

  test "should get search" do
    get search_locations_url, params: { q: "freezer" }
    assert_response :success
  end

  test "should get show" do
    get location_url(@location.barcode)
    assert_response :success
  end

  test "should get new" do
    get new_location_url
    assert_response :success
  end

  test "should create location" do
    assert_difference("Location.count") do
      post locations_url, params: { location: { name: "Garage freezer" } }
    end
    assert_redirected_to location_url(Location.last.barcode)
  end
end
