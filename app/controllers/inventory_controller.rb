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
end
