class InventoryController < ApplicationController
  def index
    @locations = Location.includes(inventory_items: :item).all

    @inventory_items = InventoryItem.includes(:location, :item)
                                  .order(created_at: :desc)
                                  .page(params[:page])
                                  .per(20)
  end

  def search
    @query = params[:q]
    @locations = Location.includes(inventory_items: :item).all

    if @query.present?
      @inventory_items = InventoryItem.joins(:item, :location)
                                    .where('LOWER(items.name) LIKE ? OR LOWER(items.barcode) LIKE ? OR LOWER(locations.name) LIKE ?',
                                           "%#{@query.downcase}%", "%#{@query.downcase}%", "%#{@query.downcase}%")
                                    .includes(:location, :item)
                                    .order(created_at: :desc)
                                    .page(params[:page])
                                    .per(20)
    else
      @inventory_items = InventoryItem.none.page(params[:page]).per(20)
    end

    render :index
  end

  def oldest_items
    # Get items stored the longest (oldest added_at first)
    @oldest_inventory_items = InventoryItem.includes(:location, :item, item: :category)
                                         .order(:added_at)
                                         .page(params[:page])
                                         .per(50)

    # Calculate days stored for statistics
    @oldest_item = InventoryItem.order(:added_at).first
    @total_old_items = InventoryItem.where('added_at < ?', 120.days.ago).count
    @very_old_items = InventoryItem.where('added_at < ?', 180.days.ago).count
  end
end
