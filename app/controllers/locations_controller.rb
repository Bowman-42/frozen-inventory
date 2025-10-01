require_relative '../services/barcode_printer'

class LocationsController < ApplicationController
  def index
    @locations = Location.includes(:inventory_items, :items).all
  end

  def search
    @query = params[:q]

    if @query.present?
      @locations = Location.includes(:inventory_items, :items)
                           .where('LOWER(name) LIKE ? OR LOWER(barcode) LIKE ? OR LOWER(description) LIKE ?',
                                  "%#{@query.downcase}%", "%#{@query.downcase}%", "%#{@query.downcase}%")
    else
      @locations = Location.none
    end

    render :index
  end

  def show
    @location = Location.find_by!(barcode: params[:barcode])
    @inventory_items = @location.inventory_items.includes(:item).order(:created_at)
  end

  def new
    @location = Location.new
  end

  def create
    @location = Location.new(location_params)

    if @location.save
      redirect_to location_path(@location.barcode), notice: 'Fridge was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def print_barcodes
    @locations = Location.where(id: params[:location_ids])

    if @locations.empty?
      redirect_to locations_path, alert: 'No locations selected for printing.'
      return
    end

    pdf = BarcodePrinter.generate_pdf(@locations, type: :location)

    send_data pdf,
              filename: "location_barcodes_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'inline'  # Changed from 'attachment' to 'inline'
  end

  private

  def location_params
    params.require(:location).permit(:name, :description)
  end
end
