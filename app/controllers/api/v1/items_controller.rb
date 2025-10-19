class Api::V1::ItemsController < Api::V1::BaseController
  def show
    item = find_item_by_barcode(params[:barcode])
    raise ActiveRecord::RecordNotFound, "Item not found" unless item

    item_data = {
      id: item.id,
      name: item.name,
      barcode: item.barcode,
      description: item.description,
      total_quantity: item.total_quantity,
      locations: item.locations_with_quantity.map do |location_data|
        {
          location: {
            id: location_data[:location].id,
            name: location_data[:location].name,
            barcode: location_data[:location].barcode,
            description: location_data[:location].description
          },
          quantity: location_data[:quantity],
          added_at: location_data[:added_at].iso8601
        }
      end
    }

    render_success(item_data)
  end
end
