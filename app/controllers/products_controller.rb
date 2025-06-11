class ProductsController < ApplicationController
  # before_action :authenticate_user!
  before_action :set_product, only: [:show]

  def index
    @products = Product.all.order(:name)
    # that's for the search
    if params[:query].present?
      sql_subquery = <<~SQL
        products.name ILIKE :query
        OR products.category ILIKE :query
        OR products.description ILIKE :query
        OR products.status ILIKE :query
        OR CAST(products.current_price AS TEXT) ILIKE :query
        OR CAST(products.last_month_volume AS TEXT) ILIKE :query
        OR CAST(products.contract_end_date AS TEXT) ILIKE :query
        OR users.company_name ILIKE :query
      SQL

      @products = Product.joins(:supplier).where(sql_subquery, query: "%#{params[:query]}%")
    else
      # that's if there is no search, the standard index call
      @products = Product.all
    end

    # Below is everything related to clicking on the header and having elements ranked alphabetically or so
    case params[:sort]
    when "name"
      @products = @products.order("products.name #{sort_order}")
    when "supplier"
      @products = @products.joins(:supplier).order("users.company_name #{sort_order}")
    when "category"
      @products = @products.order("products.category #{sort_order}")
    when "price"
      @products = @products.order("products.current_price #{sort_order}")
    when "contract_end"
      @products = @products.order("products.contract_end_date #{sort_order}")
    when "volume"
      @products = @products.order("products.last_month_volume #{sort_order}")
    when "status"
      @products = @products.order("products.status #{sort_order}")
    else
      @products = @products.order("products.name ASC") # default
    end
  end

  private

  def sort_order
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

  def show
    @supplier       = @product.supplier
    @renegotiations = @product.renegotiations.order(created_at: :desc)
  end


  def set_product
    @product = Product.find(params[:id])
  end
end
