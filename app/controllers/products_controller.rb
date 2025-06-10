class ProductsController < ApplicationController

  # function for the page showing the list of products
  def index
    @products = Product.all
  end

end
