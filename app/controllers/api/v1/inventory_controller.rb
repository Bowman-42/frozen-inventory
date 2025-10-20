class Api::V1::InventoryController < Api::V1::BaseController
  def add_item
    location_barcode = params[:location_barcode]
    item_barcode = params[:item_barcode]
    quantity = 1

    return render_error('Location barcode is required') if location_barcode.blank?
    return render_error('Item barcode is required') if item_barcode.blank?

    location = Location.find_by(barcode: location_barcode)
    return render_error('Location not found') unless location

    item = find_item_by_barcode(item_barcode)
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
    # Accept both parameter names for backward compatibility
    individual_barcode = params[:individual_barcode] || params[:item_barcode]

    return render_error('Individual barcode is required') if individual_barcode.blank?

    # Find the individual item by its barcode
    reusable_barcode = ReusableBarcode.find_by(barcode: individual_barcode)
    return render_error('Individual item not found') unless reusable_barcode

    individual_item = IndividualInventoryItem.find_by(reusable_barcode: reusable_barcode)
    return render_error('Individual item not found in inventory') unless individual_item

    location = individual_item.location
    item = individual_item.item
    inventory_item = individual_item.inventory_item

    ActiveRecord::Base.transaction do
      removed_info = inventory_item.remove_individual_item!(target: individual_item)

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

  def move_item
    to_location_barcode = params[:to_location_barcode]
    # Accept both parameter names for backward compatibility
    individual_barcode = params[:individual_barcode] || params[:item_barcode]

    return render_error('To location barcode is required') if to_location_barcode.blank?
    return render_error('Individual barcode is required') if individual_barcode.blank?

    to_location = Location.find_by(barcode: to_location_barcode)
    return render_error('To location not found') unless to_location

    # Find the individual item by its barcode
    reusable_barcode = ReusableBarcode.find_by(barcode: individual_barcode)
    return render_error('Individual item not found') unless reusable_barcode

    individual_item = IndividualInventoryItem.find_by(reusable_barcode: reusable_barcode)
    return render_error('Individual item not found in inventory') unless individual_item

    from_location = individual_item.location
    item = individual_item.item
    from_inventory_item = individual_item.inventory_item

    ActiveRecord::Base.transaction do
      # Remove the specific individual item from source location (preserving storage time info)
      removed_info = from_inventory_item.remove_individual_item!(target: individual_item)
      original_added_at = removed_info[:original_added_at]

      # Find or create inventory item in destination location
      to_inventory_item = InventoryItem.find_by(location: to_location, item: item)

      if to_inventory_item
        # Add individual item to existing inventory item with preserved timestamp
        individual_item = to_inventory_item.add_individual_item!(added_at: original_added_at)
      else
        # Create new inventory item in destination location
        to_inventory_item = InventoryItem.create!(
          location: to_location,
          item: item,
          added_at: original_added_at
        )
        individual_item = to_inventory_item.add_individual_item!(added_at: original_added_at)
      end

      response_data = {
        moved_individual_item: {
          individual_barcode: individual_item.individual_barcode,
          original_added_at: original_added_at.iso8601,
          storage_days: removed_info[:storage_days].round(1)
        },
        from_location: {
          id: from_location.id,
          name: from_location.name,
          barcode: from_location.barcode,
          remaining_quantity: from_inventory_item.destroyed? ? 0 : from_inventory_item.quantity
        },
        to_location: {
          id: to_location.id,
          name: to_location.name,
          barcode: to_location.barcode,
          new_quantity: to_inventory_item.quantity
        },
        item: {
          id: item.id,
          name: item.name,
          barcode: item.barcode
        }
      }

      render_success(response_data, 'Item moved successfully')
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error("Validation failed: #{e.message}")
  end
end
