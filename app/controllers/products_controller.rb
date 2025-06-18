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
      @products = Product.where(procurement: current_user)
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

        # Parse CSV and clean headers
        raw_csv = CSV.parse(file_content, headers: true, col_sep: ',', quote_char: '"', liberal_parsing: true)
        cleaned_headers = raw_csv.headers.map(&:strip)
        csv = CSV.parse(file_content, headers: cleaned_headers, col_sep: ',', quote_char: '"', liberal_parsing: true)

        imported_count = 0
        skipped_count = 0

        csv.each_with_index do |row, index|
          product_data = row.to_h.transform_keys(&:strip)

          # Skip empty or clearly invalid rows (e.g. duplicated header row)
          if product_data["name"].to_s.strip.downcase == "name" || product_data["supplier_email"].to_s.strip.downcase == "supplier_email"
            Rails.logger.warn "⚠️ Row #{index + 2} skipped: duplicate or invalid header row"
            skipped_count += 1
            next
          end

          # Extract and sanitize supplier fields
          company_name   = product_data["supplier_company_name"].to_s.strip
          supplier_email = product_data["supplier_email"].to_s.strip
          contact_name   = product_data["supplier_contact"].to_s.strip
          contact_email  = product_data["supplier_contact_email"].to_s.strip

          if company_name.blank?
            Rails.logger.warn "❌ Row #{index + 2} skipped: missing supplier company name"
            skipped_count += 1
            next
          end

          # Choose a valid email
          email = supplier_email.presence || contact_email.presence
          if email.blank? || email.downcase == "supplier_email" || !(email =~ URI::MailTo::EMAIL_REGEXP)
            Rails.logger.warn "❌ Row #{index + 2} skipped: missing or invalid email"
            skipped_count += 1
            next
          end

          # Find or create supplier
          supplier = User.find_or_initialize_by(email: email, role: "supplier")
          if supplier.new_record?
            supplier.assign_attributes(
              company_name: company_name,
              email: email,
              contact: contact_name,
              contact_email: contact_email,
              password: "ImportPass123!" # secure temporary password
            )
            supplier.save!
            Rails.logger.info "✅ Created new supplier '#{supplier.company_name}'"
          else
            Rails.logger.info "➡️ Reused existing supplier '#{supplier.company_name}'"
          end

          # Fallback for development if user not logged in
          procurement = current_user || User.find_by(role: "procurement") || User.first
          if procurement.nil?
            Rails.logger.warn "❌ Row #{index + 2} skipped: current_user (procurement) missing"
            skipped_count += 1
            next
          end

          # Parse contract_end_date
          begin
            contract_date = Date.strptime(product_data["contract_end_date"].to_s.strip, "%d/%m/%Y")
          rescue ArgumentError
            Rails.logger.warn "❌ Row #{index + 2} skipped: invalid date format '#{product_data["contract_end_date"]}'"
            skipped_count += 1
            next
          end

          # Create and save the product
          product = Product.new(
            name: product_data["name"].to_s.strip,
            category: product_data["category"].to_s.strip,
            description: product_data["description"].to_s.strip,
            current_price: product_data["current_price"],
            last_month_volume: product_data["last_month_volume"],
            status: product_data["status"] || "Pending",
            contract_end_date: contract_date,
            supplier: supplier,
            procurement: procurement
          )

          if product.save
            Rails.logger.info "✅ Imported product '#{product.name}'"
            imported_count += 1
          else
            Rails.logger.warn "❌ Row #{index + 2} skipped: product invalid - #{product.errors.full_messages.join(', ')}"
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


  def set_product
    @product = Product.find(params[:id])
  end
end
