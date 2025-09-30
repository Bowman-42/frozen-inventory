class ItemsController < ApplicationController
  def index
    @items = Item.includes(:inventory_items, :locations)
                 .order(:name)
                 .page(params[:page])
                 .per(20)
  end

  def show
    @item = Item.find_by!(barcode: params[:barcode])
    @inventory_items = @item.inventory_items.includes(:location).order(:created_at)
  end

  def new
    @item = Item.new
  end

  def create
    @item = Item.new(item_params)

    if @item.save
      redirect_to item_path(@item.barcode), notice: 'Item was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def item_params
    params.require(:item).permit(:name, :barcode, :description)
  end
end
