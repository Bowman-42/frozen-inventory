require "test_helper"

class ItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @item = items(:one)
  end

  test "should get index" do
    get items_url
    assert_response :success
  end

  test "should get search" do
    get search_items_url, params: { q: "peas" }
    assert_response :success
  end

  test "should get show" do
    get item_url(@item.barcode)
    assert_response :success
  end

  test "should get new" do
    get new_item_url
    assert_response :success
  end

  test "should create item" do
    assert_difference("Item.count") do
      post items_url, params: { item: { name: "Corn", category_id: categories(:one).id } }
    end
    assert_redirected_to item_url(Item.last.barcode)
  end

  test "should get edit" do
    get edit_item_url(@item.barcode)
    assert_response :success
  end

  test "should update item" do
    patch item_url(@item.barcode), params: { item: { name: "Green peas" } }
    assert_redirected_to item_url(@item.barcode)
    assert_equal "Green peas", @item.reload.name
  end
end
