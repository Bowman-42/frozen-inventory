class CategoriesController < ApplicationController
  before_action :set_category, only: [:show, :edit, :update, :destroy]

  def index
    @categories = Category.ordered.includes(:items)
  end

  def search
    @query = params[:q]

    if @query.present?
      @categories = Category.where('LOWER(name) LIKE ? OR LOWER(description) LIKE ?',
                                  "%#{@query.downcase}%", "%#{@query.downcase}%")
                           .ordered.includes(:items)
    else
      @categories = Category.none
    end

    render :index
  end

  def show
    @items = @category.items.includes(:inventory_items, :locations).order(:name)
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to @category, notice: 'Category was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to @category, notice: 'Category was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    redirect_to categories_path, notice: 'Category was successfully deleted.'
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :description)
  end
end
