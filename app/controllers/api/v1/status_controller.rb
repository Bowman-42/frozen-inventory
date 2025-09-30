class Api::V1::StatusController < Api::V1::BaseController
  def show
    status_data = {
      status: 'ok',
      version: '1.0.0',
      timestamp: Time.current.iso8601,
      database: database_status
    }
    render_success(status_data)
  end

  private

  def database_status
    {
      connected: ActiveRecord::Base.connected?,
      locations_count: Location.count,
      items_count: Item.count,
      inventory_items_count: InventoryItem.count
    }
  rescue StandardError => e
    { connected: false, error: e.message }
  end
end
