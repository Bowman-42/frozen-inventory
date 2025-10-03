require_relative '../services/barcode_printer'

class ItemsController < ApplicationController
  def index
    @items = Item.includes(:inventory_items, :locations, :category)

    # Filter by category if specified
    if params[:category_id].present?
      @items = @items.where(category_id: params[:category_id])
    end

    @items = @items.order(:name)
                   .page(params[:page])
                   .per(20)
  end

  def search
    @query = params[:q]

    if @query.present?
      @items = Item.includes(:inventory_items, :locations, :category)
                   .where('LOWER(name) LIKE ? OR LOWER(barcode) LIKE ? OR LOWER(description) LIKE ?',
                          "%#{@query.downcase}%", "%#{@query.downcase}%", "%#{@query.downcase}%")

      # Apply category filter to search results if specified
      if params[:category_id].present?
        @items = @items.where(category_id: params[:category_id])
      end

      @items = @items.order(:name)
                     .page(params[:page])
                     .per(20)
    else
      @items = Item.none.page(params[:page]).per(20)
    end

    render :index
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

  def edit
    @item = Item.find_by!(barcode: params[:barcode])
  end

  def update
    @item = Item.find_by!(barcode: params[:barcode])

    if @item.update(item_params)
      redirect_to item_path(@item.barcode), notice: 'Item was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def print_barcodes
    @items = Item.where(id: params[:item_ids])

    if @items.empty?
      redirect_to items_path, alert: 'No items selected for printing.'
      return
    end

    # Process copy quantities
    copy_quantities = params[:copies] || {}
    items_with_copies = []

    @items.each do |item|
      copies = copy_quantities[item.id.to_s].to_i
      copies = 1 if copies < 1  # Default to 1 copy if invalid
      copies.times { items_with_copies << item }
    end

    pdf = BarcodePrinter.generate_pdf(items_with_copies, type: :item)

    total_labels = items_with_copies.count
    send_data pdf,
              filename: "item_barcodes_#{total_labels}_labels_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

  private

  def item_params
    params.require(:item).permit(:name, :description, :category_id)
  end
end
