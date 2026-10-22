require "test_helper"

class InventoryControllerTest < ActionDispatch::IntegrationTest
  test "should get root" do
    get root_url
    assert_response :success
  end

  test "should get index" do
    get inventory_url
    assert_response :success
  end

  test "should get search" do
    get inventory_search_url, params: { q: "peas" }
    assert_response :success
  end

  test "should get oldest" do
    get inventory_oldest_url
    assert_response :success
  end

  test "should get history" do
    get inventory_history_url
    assert_response :success
  end

  test "should get manual remove" do
    get inventory_manual_remove_url, params: { q: "peas" }
    assert_response :success
  end
end
