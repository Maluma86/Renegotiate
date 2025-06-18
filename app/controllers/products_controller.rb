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
    unless params[:file].present?
      return redirect_to(import_products_path, alert: "Please upload a CSV file.")
    end

    begin
      # Read and normalize encoding + strip BOM
      file_content = params[:file].read
      file_content.force_encoding("UTF-8")
      file_content.sub!(/\A\uFEFF/, "")

      # Parse CSV with header stripping
      csv = CSV.parse(
        file_content,
        headers: true,
        header_converters: ->(h){ h.strip },
        col_sep: ",", quote_char: '"', liberal_parsing: true
      )

      imported_count = 0
      skipped_count  = 0

      csv.each_with_index do |row, idx|
        data = row.to_h.transform_keys(&:strip)

        # skip repeated header rows
        if data["name"].to_s.strip.downcase == "name"
          Rails.logger.warn "⚠️ Row #{idx + 2} skipped: duplicate header"
          skipped_count += 1
          next
        end

        # supplier fields
        company_name  = data["supplier_company_name"].to_s.strip
        raw_email     = data["supplier_email"].presence || data["supplier_contact_email"].presence
        contact_name  = data["supplier_contact"].to_s.strip

        if company_name.blank?
          Rails.logger.warn "❌ Row #{idx + 2} skipped: missing supplier company name"
          skipped_count += 1
          next
        end

        email = raw_email.to_s.strip.downcase
        unless email =~ URI::MailTo::EMAIL_REGEXP
          Rails.logger.warn "❌ Row #{idx + 2} skipped: invalid email '#{raw_email}'"
          skipped_count += 1
          next
        end

        # find-or-init supplier by email only
        supplier = User.find_or_initialize_by(email: email)
        if supplier.new_record?
          supplier.assign_attributes(
            role:          "supplier",
            company_name:  company_name,
            contact:       contact_name,
            contact_email: data["supplier_contact_email"].to_s.strip,
            password:      "ImportPass123!"
          )
          supplier.save!
          Rails.logger.info "✅ Created new supplier '#{supplier.company_name}'"
        else
          # ensure role is set correctly
          supplier.update(role: "supplier") if supplier.role != "supplier"
          Rails.logger.info "➡️ Reused existing supplier '#{supplier.company_name}'"
        end

        # procurement fallback
        procurement = current_user || User.find_by(role: "procurement") || User.first
        unless procurement
          Rails.logger.warn "❌ Row #{idx + 2} skipped: procurement user missing"
          skipped_count += 1
          next
        end

        # parse date
        begin
          contract_date = Date.strptime(data["contract_end_date"].to_s.strip, "%d/%m/%Y")
        rescue ArgumentError
          Rails.logger.warn "❌ Row #{idx + 2} skipped: invalid date '#{data["contract_end_date"]}'"
          skipped_count += 1
          next
        end

        # build product
        product = Product.new(
          name:               data["name"].to_s.strip,
          category:           data["category"].to_s.strip,
          description:        data["description"].to_s.strip,
          current_price:      data["current_price"],
          last_month_volume:  data["last_month_volume"],
          status:             data["status"].presence || "Pending",
          contract_end_date:  contract_date,
          supplier:           supplier,
          procurement:        procurement
        )

        if product.save
          Rails.logger.info "✅ Imported product '#{product.name}'"
          imported_count += 1
        else
          Rails.logger.warn "❌ Row #{idx + 2} skipped: product invalid - #{product.errors.full_messages.join(', ')}"
          skipped_count += 1
        end
      end

      notice = "#{imported_count} product(s) imported successfully."
      notice += " #{skipped_count} row(s) skipped." if skipped_count.positive?
      redirect_to products_path, notice: notice

    rescue CSV::MalformedCSVError => e
      redirect_to import_products_path, alert: "CSV format issue: #{e.message}"
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
