require "test_helper"

class InventoryControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get inventory_index_url
    assert_response :success
  end

  test "should get search" do
    get inventory_search_url
    assert_response :success
  end
end
