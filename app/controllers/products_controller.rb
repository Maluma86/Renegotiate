class ProductsController < ApplicationController

  # function for the page showing the list of products
  def index
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
      @products = Product.all
    end
  end
end
