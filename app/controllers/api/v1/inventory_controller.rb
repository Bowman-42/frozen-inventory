class Api::V1::InventoryController < Api::V1::BaseController
  def add_item
    location_barcode = params[:location_barcode]
    item_barcode = params[:item_barcode]
    quantity = 1

    return render_error('Location barcode is required') if location_barcode.blank?
    return render_error('Item barcode is required') if item_barcode.blank?

    location = Location.find_by(barcode: location_barcode)
    return render_error('Location not found') unless location

    item = Item.find_by(barcode: item_barcode)
    return render_error('Item not found') unless item

    inventory_item = InventoryItem.find_by(location: location, item: item)

    ActiveRecord::Base.transaction do
      if inventory_item
        individual_item = inventory_item.add_individual_item!
      else
        inventory_item = InventoryItem.create!(
          location: location,
          item: item,
          added_at: Time.current
        )
        individual_item = inventory_item.add_individual_item!
      end

      # Enhanced response with individual item info
      response_data = {
        inventory_item: {
          id: inventory_item.id,
          quantity: inventory_item.quantity,
          added_at: inventory_item.added_at.iso8601
        },
        individual_item: {
          individual_barcode: individual_item.individual_barcode,
          is_legacy_barcode: individual_item.reusable_barcode.legacy_barcode?,
          sequence_number: individual_item.sequence_number
        },
        location: {
          id: location.id,
          name: location.name,
          barcode: location.barcode
        },
        item: {
          id: item.id,
          name: item.name,
          barcode: item.barcode
        }
      }

      message = individual_item.reusable_barcode.legacy_barcode? ?
        'Item added successfully' :
        "Item added successfully. Individual barcode: #{individual_item.individual_barcode}"

      render_success(response_data, message)
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error("Validation failed: #{e.message}")
  end

  def remove_item
    location_barcode = params[:location_barcode]
    item_barcode = params[:item_barcode]
    quantity = 1

    return render_error('Location barcode is required') if location_barcode.blank?
    return render_error('Item barcode is required') if item_barcode.blank?

    location = Location.find_by(barcode: location_barcode)
    return render_error('Location not found') unless location

    item = Item.find_by(barcode: item_barcode)
    return render_error('Item not found') unless item

    inventory_item = InventoryItem.find_by(location: location, item: item)
    return render_error('Item not found in this location') unless inventory_item

    ActiveRecord::Base.transaction do
      removed_info = inventory_item.remove_individual_item!(strategy: :fifo)

      if removed_info[:completely_removed]
        response_data = {
          message: 'Item completely removed from location',
          removed_quantity: 1,
          removed_individual_item: {
            individual_barcode: removed_info[:individual_barcode],
            was_legacy_barcode: removed_info[:individual_barcode] == item.barcode,
            storage_days: removed_info[:storage_days].round(1)
          }
        }
      else
        response_data = {
          inventory_item: {
            id: inventory_item.id,
            quantity: inventory_item.quantity,
            added_at: inventory_item.added_at.iso8601
          },
          removed_quantity: 1,
          removed_individual_item: {
            individual_barcode: removed_info[:individual_barcode],
            was_legacy_barcode: removed_info[:individual_barcode] == item.barcode,
            storage_days: removed_info[:storage_days].round(1)
          }
        }
      end

      response_data.merge!({
        location: {
          id: location.id,
          name: location.name,
          barcode: location.barcode
        },
        item: {
          id: item.id,
          name: item.name,
          barcode: item.barcode
        }
      })

      render_success(response_data, 'Item removed successfully')
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error("Validation failed: #{e.message}")
  end
end
