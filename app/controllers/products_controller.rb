class ProductsController < ApplicationController
  # before_action :authenticate_user!
  before_action :set_product, only: [:show]

  def index
    @products = Product.all.order(:name)
  end

  def show
    @supplier       = @product.supplier
    @renegotiations = @product.renegotiations.order(created_at: :desc)
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end
end
