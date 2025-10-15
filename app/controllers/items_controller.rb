require_relative '../services/barcode_printer'
require 'ostruct'

class ItemsController < ApplicationController
  def index
    @items = Item.includes(:inventory_items, :locations, :category)

    # Filter by category if specified
    if params[:category_id].present?
      @items = @items.where(category_id: params[:category_id])
    end

    # Handle sorting
    @sort_column = params[:sort] || 'name'
    @sort_direction = params[:direction] || 'asc'

    case @sort_column
    when 'name'
      @items = @items.order("items.name #{@sort_direction}")
    when 'category'
      @items = @items.left_joins(:category).order("categories.name #{@sort_direction}")
    when 'quantity'
      @items = @items.order("items.total_quantity #{@sort_direction}")
    else
      @items = @items.order(:name)
    end

    @items = @items.page(params[:page]).per(20)

    # Preload oldest inventory items to avoid N+1 queries
    item_ids = @items.map(&:id)
    @oldest_inventory_items = InventoryItem.oldest_per_item
                                          .where(item_id: item_ids)
                                          .group_by(&:item_id)
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

      # Handle sorting for search results
      @sort_column = params[:sort] || 'name'
      @sort_direction = params[:direction] || 'asc'

      case @sort_column
      when 'name'
        @items = @items.order("items.name #{@sort_direction}")
      when 'category'
        @items = @items.left_joins(:category).order("categories.name #{@sort_direction}")
      when 'quantity'
        @items = @items.order("items.total_quantity #{@sort_direction}")
      else
        @items = @items.order(:name)
      end

      @items = @items.page(params[:page]).per(20)

      # Preload oldest inventory items for search results
      item_ids = @items.map(&:id)
      @oldest_inventory_items = InventoryItem.oldest_per_item
                                            .where(item_id: item_ids)
                                            .group_by(&:item_id)
    else
      @items = Item.none.page(params[:page]).per(20)
      @sort_column = params[:sort] || 'name'
      @sort_direction = params[:direction] || 'asc'
      @oldest_inventory_items = {}
    end

    render :index
  end

  def show
    @item = Item.find_by!(barcode: params[:barcode])
    @inventory_items = @item.inventory_items.includes(:location).order(:created_at)

    # Find the oldest storage location for this item
    @oldest_inventory_item = @item.inventory_items.includes(:location).order(:added_at).first
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
    items_to_print = []

    @items.each do |item|
      copies = copy_quantities[item.id.to_s].to_i
      copies = 1 if copies < 1

      copies.times do
        # After migration: generate individual barcodes for printing
        items_to_print << generate_individual_barcode_for_printing(item)
      end
    end

    pdf = BarcodePrinter.generate_pdf(items_to_print, type: :item)

    send_data pdf,
              filename: "item_barcodes_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

  private

  def generate_individual_barcode_for_printing(item)
    # Generate individual barcode for printing (not for inventory)
    sequence = ItemIdCounter.next_for_item(item)
    individual_barcode = "#{item.barcode}-#{sequence.to_s.rjust(5, '0')}"

    # Format name with category like the BarcodePrinter expects for Item instances
    formatted_name = item.category&.name ? "#{item.name}  #{item.category.name}" : item.name

    # Create print-ready object (not database record)
    OpenStruct.new(
      barcode: individual_barcode,
      name: formatted_name,
      category: item.category&.name,
      description: item.description
    )
  end

  def item_params
    params.require(:item).permit(:name, :description, :category_id)
  end
end
