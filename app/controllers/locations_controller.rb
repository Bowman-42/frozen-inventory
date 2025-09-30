class LocationsController < ApplicationController
  def index
    @locations = Location.includes(:inventory_items, :items).all
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

  private

  def location_params
    params.require(:location).permit(:name, :barcode, :description)
  end
end
