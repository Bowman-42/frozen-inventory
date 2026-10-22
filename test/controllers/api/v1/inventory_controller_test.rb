require "test_helper"

class Api::V1::InventoryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @item = Item.create!(name: "Peas")
    @freezer = Location.create!(name: "Freezer")
    @fridge = Location.create!(name: "Fridge")
  end

  # Mimics printing a label: the number comes from the counter, nothing is stored yet
  def print_label
    "#{@item.barcode}-#{ItemIdCounter.next_for_item(@item).to_s.rjust(5, '0')}"
  end

  def add(label, location = @freezer)
    post "/api/v1/add-item", params: { location_barcode: location.barcode, item_barcode: label }, as: :json
  end

  def json
    JSON.parse(response.body)
  end

  test "adding stores the item under the scanned label even when an older barcode is free" do
    old_label = print_label
    new_label = print_label

    add(old_label)
    assert_response :success
    post "/api/v1/remove-item", params: { item_barcode: old_label }, as: :json
    assert_response :success
    assert_not ReusableBarcode.find_by(barcode: old_label).in_use

    add(new_label)
    assert_response :success
    assert_equal new_label, json.dig("data", "individual_item", "individual_barcode")

    post "/api/v1/remove-item", params: { item_barcode: new_label }, as: :json
    assert_response :success
  end

  test "scanning the same label twice does not add a second item" do
    label = print_label

    add(label)
    assert_response :success
    add(label)
    assert_response :unprocessable_entity
    assert_equal "This barcode is already in inventory", json["error"]
    assert_equal 1, IndividualInventoryItem.where(item: @item).count
  end

  test "moving keeps the label barcode and the original added date" do
    label = print_label
    add(label)
    added_at = IndividualInventoryItem.last.added_at

    post "/api/v1/move-item", params: { item_barcode: label, to_location_barcode: @fridge.barcode }, as: :json
    assert_response :success
    assert_equal label, json.dig("data", "moved_individual_item", "individual_barcode")

    moved = ReusableBarcode.find_by(barcode: label).individual_inventory_item
    assert_equal @fridge, moved.location
    assert_in_delta added_at, moved.added_at, 1.second
  end
end
