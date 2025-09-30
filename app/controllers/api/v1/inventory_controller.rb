class Api::V1::InventoryController < Api::V1::BaseController
  def add_item
    location_barcode = params[:location_barcode]
    item_barcode = params[:item_barcode]
    quantity = params[:quantity]&.to_i || 1

    return render_error('Location barcode is required') if location_barcode.blank?
    return render_error('Item barcode is required') if item_barcode.blank?
    return render_error('Quantity must be greater than 0') if quantity <= 0

    location = Location.find_by(barcode: location_barcode)
    return render_error('Location not found') unless location

    item = Item.find_by(barcode: item_barcode)
    return render_error('Item not found') unless item

    inventory_item = InventoryItem.find_by(location: location, item: item)

    ActiveRecord::Base.transaction do
      if inventory_item
        inventory_item.update!(quantity: inventory_item.quantity + quantity)
      else
        inventory_item = InventoryItem.create!(
          location: location,
          item: item,
          quantity: quantity,
          added_at: Time.current
        )
      end

      response_data = {
        inventory_item: {
          id: inventory_item.id,
          quantity: inventory_item.quantity,
          added_at: inventory_item.added_at.iso8601
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

      render_success(response_data, 'Item added successfully')
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error("Validation failed: #{e.message}")
  end

  def remove_item
    location_barcode = params[:location_barcode]
    item_barcode = params[:item_barcode]
    quantity = params[:quantity]&.to_i || 1

    return render_error('Location barcode is required') if location_barcode.blank?
    return render_error('Item barcode is required') if item_barcode.blank?
    return render_error('Quantity must be greater than 0') if quantity <= 0

    location = Location.find_by(barcode: location_barcode)
    return render_error('Location not found') unless location

    item = Item.find_by(barcode: item_barcode)
    return render_error('Item not found') unless item

    inventory_item = InventoryItem.find_by(location: location, item: item)
    return render_error('Item not found in this location') unless inventory_item

    ActiveRecord::Base.transaction do
      if inventory_item.quantity <= quantity
        inventory_item.destroy!
        response_data = {
          message: 'Item completely removed from location',
          removed_quantity: inventory_item.quantity
        }
      else
        inventory_item.update!(quantity: inventory_item.quantity - quantity)
        response_data = {
          inventory_item: {
            id: inventory_item.id,
            quantity: inventory_item.quantity,
            added_at: inventory_item.added_at.iso8601
          },
          removed_quantity: quantity
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
