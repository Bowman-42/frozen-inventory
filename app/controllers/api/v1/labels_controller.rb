class Api::V1::LabelsController < Api::V1::BaseController
  # Check whether a printed label is stored on an item in inventory, and list all
  # items of that product so a mismatched label can be assigned to the right one
  def show
    item = find_item_by_barcode(params[:barcode])
    raise ActiveRecord::RecordNotFound, "Item not found" unless item

    render_success(label_data(params[:barcode], item))
  end

  # Store an item in inventory under the scanned label, keeping its location and added date
  def relabel
    label_barcode = params[:label_barcode]
    unit_id = params[:unit_id]

    return render_error('Label barcode is required') if label_barcode.blank?
    return render_error('Unit is required') if unit_id.blank?

    unit = IndividualInventoryItem.find_by(id: unit_id)
    return render_error('Individual item not found in inventory') unless unit

    item = find_item_by_barcode(label_barcode)
    return render_error('Label belongs to a different item') unless item == unit.item

    label = ReusableBarcode.find_by(barcode: label_barcode, item: item)
    return render_error('Scan an individual label') if label.nil? || label.legacy_barcode?

    unit.relabel!(label)

    render_success(label_data(label_barcode, item), 'Label repaired')
  rescue ActiveRecord::RecordInvalid => e
    render_error("Validation failed: #{e.message}")
  end

  private

  def label_data(label_barcode, item)
    units = item.individual_inventory_items.includes(:location, :reusable_barcode).oldest_first

    {
      label: label_barcode,
      item: {
        id: item.id,
        name: item.name,
        barcode: item.barcode
      },
      stored: units.any? { |unit| unit.individual_barcode == label_barcode },
      units: units.map do |unit|
        {
          id: unit.id,
          individual_barcode: unit.individual_barcode,
          added_at: unit.added_at.iso8601,
          location: {
            id: unit.location.id,
            name: unit.location.name,
            barcode: unit.location.barcode
          }
        }
      end
    }
  end
end
