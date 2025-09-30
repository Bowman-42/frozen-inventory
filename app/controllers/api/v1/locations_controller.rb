class Api::V1::LocationsController < Api::V1::BaseController
  def show
    location = Location.find_by!(barcode: params[:barcode])

    location_data = {
      id: location.id,
      name: location.name,
      barcode: location.barcode,
      description: location.description,
      total_items: location.total_items,
      inventory_items: location.inventory_items.includes(:item).map do |inv_item|
        {
          item: {
            id: inv_item.item.id,
            name: inv_item.item.name,
            barcode: inv_item.item.barcode,
            description: inv_item.item.description
          },
          quantity: inv_item.quantity,
          added_at: inv_item.added_at.iso8601
        }
      end
    }

    render_success(location_data)
  end
end
