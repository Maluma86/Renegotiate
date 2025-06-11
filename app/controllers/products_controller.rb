require 'csv'

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

  # function to import data from the index page
  def import
    # Just renders the form view
  end

  def upload
    if params[:file].present?
      begin
        file_content = params[:file].read

        # First parse to clean headers
        raw_csv = CSV.parse(file_content, headers: true, col_sep: ',', quote_char: '"')
        cleaned_headers = raw_csv.headers.map { |h| h.to_s.strip }

        # Re-parse with clean headers
        csv = CSV.parse(file_content, headers: cleaned_headers, col_sep: ',', quote_char: '"', liberal_parsing: true)

        imported_count = 0
        skipped_count = 0

        csv.each_with_index do |row, index|
          product_data = row.to_h

          # for supplier
          required_supplier_fields = %w[supplier_email supplier_company_name]
          if required_supplier_fields.any? { |key| product_data[key].blank? }
            Rails.logger.warn "Row #{index + 2} skipped: missing supplier info"
            skipped_count += 1
            next
          end

          supplier = User.find_or_create_by(email: product_data["supplier_email"]) do |user|
            user.company_name = product_data["supplier_company_name"]
            user.contact = product_data["supplier_contact"]
            user.contact_email = product_data["supplier_contact_email"]
            user.role = "supplier"
            user.password = "ImportPass123!" # Required by Devise
          end

          # the procurement_id is the one of the user who is upload it
          procurement = current_user

          if supplier.nil?
            Rails.logger.info "➡️ Supplier '#{supplier.company_name}' (id: #{supplier.id}) created or found"
            skipped_count += 1
            next
          end

          product = Product.new(
            name: product_data["name"],
            category: product_data["category"],
            description: product_data["description"],
            current_price: product_data["current_price"],
            last_month_volume: product_data["last_month_volume"],
            status: product_data["status"] || "Pending",
            contract_end_date: product_data["contract_end_date"],
            supplier: supplier,
            procurement: procurement
          )

          if product.save
            Rails.logger.info "✅ Product '#{product.name}' created successfully."
            imported_count += 1
          else
            Rails.logger.warn "❌ Product validation failed on row #{index + 2}: #{product.errors.full_messages.join(', ')}"
            skipped_count += 1
          end
        end

        notice = "#{imported_count} product(s) imported successfully."
        notice += " #{skipped_count} row(s) skipped." if skipped_count > 0

        redirect_to products_path, notice: notice
      rescue CSV::MalformedCSVError => e
        redirect_to import_products_path, alert: "CSV format issue: #{e.message}"
      end
    else
      redirect_to import_products_path, alert: "Please upload a CSV file."
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

  private

  def set_product
    @product = Product.find(params[:id])
  end
end
