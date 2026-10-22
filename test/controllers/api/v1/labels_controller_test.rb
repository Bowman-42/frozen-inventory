require "test_helper"

class Api::V1::LabelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @item = Item.create!(name: "Peas")
    @freezer = Location.create!(name: "Freezer")
  end

  # Mimics printing a label: the number comes from the counter, nothing is stored yet
  def print_label
    "#{@item.barcode}-#{ItemIdCounter.next_for_item(@item).to_s.rjust(5, '0')}"
  end

  def add(label)
    post "/api/v1/add-item", params: { location_barcode: @freezer.barcode, item_barcode: label }, as: :json
    assert_response :success
    ReusableBarcode.find_by!(barcode: label).individual_inventory_item
  end

  # Recreates what the old server did: a label scanned on add, but the item stored under another barcode
  def mismatch(label, stored_as)
    unit = add(stored_as)
    ReusableBarcode.create!(item: @item, barcode: label, in_use: false)
    unit
  end

  def json
    JSON.parse(response.body)
  end

  test "show reports a label stored on an item" do
    label = print_label
    unit = add(label)

    get "/api/v1/labels/#{label}"
    assert_response :success
    assert json.dig("data", "stored")
    assert_equal [unit.id], json.dig("data", "units").map { |u| u["id"] }
    assert_equal "Freezer", json.dig("data", "units", 0, "location", "name")
  end

  test "show lists all items of the product when the label is not stored" do
    stored_as = print_label
    label = print_label
    unit = mismatch(label, stored_as)

    get "/api/v1/labels/#{label}"
    assert_response :success
    assert_not json.dig("data", "stored")
    assert_equal stored_as, json.dig("data", "units", 0, "individual_barcode")
    assert_equal unit.id, json.dig("data", "units", 0, "id")
  end

  test "relabel stores the item under the label and keeps its added date" do
    stored_as = print_label
    label = print_label
    unit = mismatch(label, stored_as)
    added_at = unit.added_at

    post "/api/v1/relabel", params: { label_barcode: label, unit_id: unit.id }, as: :json
    assert_response :success
    assert json.dig("data", "stored")

    unit.reload
    assert_equal label, unit.individual_barcode
    assert_equal label.split("-").last.to_i, unit.sequence_number
    assert_in_delta added_at, unit.added_at, 1.second
    assert ReusableBarcode.find_by(barcode: label).in_use
    assert_not ReusableBarcode.find_by(barcode: stored_as).in_use

    post "/api/v1/remove-item", params: { item_barcode: label }, as: :json
    assert_response :success
  end

  test "relabel swaps barcodes when another item holds the label" do
    first_label = print_label
    second_label = print_label
    # Like the old server's chains: each package stored under the other one's label
    first = add(second_label)
    second = add(first_label)

    post "/api/v1/relabel", params: { label_barcode: first_label, unit_id: first.id }, as: :json
    assert_response :success

    assert_equal first_label, first.reload.individual_barcode
    assert_equal second_label, second.reload.individual_barcode
    assert ReusableBarcode.find_by(barcode: first_label).in_use
    assert ReusableBarcode.find_by(barcode: second_label).in_use
  end

  test "relabel rejects a label of another product" do
    unit = add(print_label)
    other_item = Item.create!(name: "Corn")
    other_label = "#{other_item.barcode}-00001"

    post "/api/v1/relabel", params: { label_barcode: other_label, unit_id: unit.id }, as: :json
    assert_response :unprocessable_entity
    assert_equal "Label belongs to a different item", json["error"]
  end
end
