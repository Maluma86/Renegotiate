class RenegotiationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: %i[new create]
  before_action :set_renegotiation, only: %i[show confirm_target set_target save_discount_targets unlock_discount_targets accept start_product_intelligence product_intelligence_status]

  def show
    # we already have @renegotiation from set_renegotiation
    @product  = @renegotiation.product
    @supplier = @product.supplier
    @questions = @renegotiation.questions.order(:created_at) # LS changed this to try to fix @questions = current_user.questions before
    @question = Question.new # for form
  end

  def new
    @renegotiation = @product.renegotiations.new(
      buyer: current_user,
      supplier_id: @product.supplier_id,
      status: "ongoing",
      min_target: calculate_min_target(@product),
      max_target: calculate_max_target(@product),
      tone: "collaborative"
    )

    if @renegotiation.save
      Rails.logger.info "Successfully created renegotiation with ID=#{@renegotiation.id}"
      redirect_to confirm_target_renegotiation_path(@renegotiation)
    else
      Rails.logger.error "Failed to save renegotiation: #{@renegotiation.errors.full_messages}"
      redirect_to product_path(@product), alert: "Failed to create renegotiation"
    end
  end

  def create
    @renegotiation = @product.renegotiations.build(renegotiation_params)
    @renegotiation.buyer_id    = current_user.id
    @renegotiation.supplier_id = @product.supplier_id

    if @renegotiation.save
      redirect_to product_path(@product), notice: "Renegotiation started!"
    else
      render :new
    end
  end

  def confirm_target
    # Stub data for testing (no AI yet)
    @ai_suggestion = {
      recommended_target: 0.40,
      confidence_score: 0.85,
      reasoning: "Test data - AI integration coming in task 7.10",
      target_price: @renegotiation.max_target, # Use the max_target from the renegotiation for Max AI page 2506171630
      min_price: @renegotiation.min_target # Use the min_target from the renegotiation for Max AI page 2506171630
    }
    @market_data = {
      average_price: 0.38,
      price_range: [0.35, 0.45]
    }
    @available_tones = %i[collaborative direct formal urgent]
  end

  def set_target
    target_price = params[:target_price]
    selected_tone = params[:tone]

    # sending the email to the supplier-----
    Rails.logger.info "attempting to send email to supplier"
    begin
        # deliver_now so we can catch errors immediately
        SupplierMailer.invite_to_renegotiation(@renegotiation.id).deliver_now
        Rails.logger.info "[RenegotiationsController] Mailer invited #{@renegotiation.supplier.email} at #{Time.current}"
      rescue => e
        Rails.logger.error "[RenegotiationsController] Failed to send mail: #{e.class} #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
      end
    #---------------------------------------

    redirect_to renegotiation_path(@renegotiation),
                notice: "Target set to #{target_price} with #{selected_tone} tone"
  end

  def save_discount_targets
    # Extract parameters
    target_percentage = params[:target_discount_percentage].to_f
    min_percentage = params[:min_discount_percentage].to_f

    # Authorization check (only buyer can set targets)
    unless @renegotiation.buyer_id == current_user.id
      return render json: { success: false, error: 'Not authorized' }, status: :forbidden
    end

    # Validation
    if target_percentage < 0 || target_percentage > 100 || min_percentage < 0 || min_percentage > 100
      return render json: { success: false, error: 'Percentages must be between 0 and 100' }, status: :unprocessable_entity
    end

    if min_percentage > target_percentage
      return render json: { success: false, error: 'Minimum cannot be greater than target' }, status: :unprocessable_entity
    end

    # Save using our model method
    begin
      @renegotiation.lock_targets!(target_percentage, min_percentage, current_user)
      render json: {
        success: true,
        message: 'Discount targets saved successfully',
        locked: true
      }
    rescue => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  def start_product_intelligence
    # Check if job is already running
    job_status_key = "product_intel_job_#{@renegotiation.id}"

    unless Rails.cache.exist?(job_status_key)
      # Mark job as running
      Rails.cache.write(job_status_key, true, expires_in: 5.minutes)

      # Queue the background job
      ProductIntelligenceJob.perform_later(@renegotiation.id)
    end

    render json: { status: 'processing' }
  end

  def product_intelligence_status
    result_key = "product_intel_result_#{@renegotiation.id}"
    recommendation_key = "product_intel_#{@renegotiation.id}_recommendation"
    forecast_key = "product_intel_#{@renegotiation.id}_forecast"
    ingredients_key = "product_intel_#{@renegotiation.id}_ingredients"
    price_drivers_key = "product_intel_#{@renegotiation.id}_price_drivers"
    risks_key = "product_intel_#{@renegotiation.id}_risks"
    strategies_key = "product_intel_#{@renegotiation.id}_strategies"
    
    Rails.logger.info "🔍 AJAX Status Check - Looking for cache keys: #{result_key}, #{recommendation_key}, #{forecast_key}, #{ingredients_key}, #{price_drivers_key}, #{risks_key}, #{strategies_key}"
    
    result = Rails.cache.read(result_key)
    recommendation = Rails.cache.read(recommendation_key)
    forecast = Rails.cache.read(forecast_key)
    ingredients = Rails.cache.read(ingredients_key)
    price_drivers = Rails.cache.read(price_drivers_key)
    risks = Rails.cache.read(risks_key)
    strategies = Rails.cache.read(strategies_key)
    
    Rails.logger.info "🔍 AJAX Status Check - Full result found: #{result.present?}, Recommendation found: #{recommendation.present?}, Forecast found: #{forecast.present?}, Ingredients found: #{ingredients.present?}, Price drivers found: #{price_drivers.present?}, Risks found: #{risks.present?}, Strategies found: #{strategies.present?}"

    if result
      # Full analysis complete
      Rails.logger.info "🔍 AJAX Status Check - Returning completed with data keys: #{result.keys}" if result.is_a?(Hash)
      render json: { status: 'completed', data: result }
    elsif recommendation || forecast || ingredients || price_drivers || risks || strategies
      # Partial result - some sections ready for streaming
      partial_data = {}
      partial_data[:recommendation] = recommendation if recommendation
      partial_data[:forecast] = forecast if forecast
      partial_data[:ingredients] = ingredients if ingredients
      partial_data[:price_drivers] = price_drivers if price_drivers
      partial_data[:risks] = risks if risks
      partial_data[:strategies] = strategies if strategies
      
      sections_ready = partial_data.keys
      Rails.logger.info "🔍 AJAX Status Check - Returning partial result with sections: #{sections_ready}"
      render json: { 
        status: 'streaming', 
        partial_data: partial_data,
        message: "Sections ready: #{sections_ready.join(', ')}, other sections processing..."
      }
    else
      Rails.logger.info "🔍 AJAX Status Check - Returning processing status"
      render json: { status: 'processing' }
    end
  end

  def unlock_discount_targets
    unless @renegotiation.buyer_id == current_user.id
      return render json: { success: false, error: 'Not authorized' }, status: :forbidden
    end

    @renegotiation.unlock_targets!
    render json: { success: true }
  end

  def accept
    unless [@renegotiation.supplier_id, @renegotiation.buyer_id].include?(current_user.id)
      return render json: { success: false, error: 'Not authorised' }, status: :forbidden
    end

  if @renegotiation.status == "done"
    return render json: { success: false, error: 'Already confirmed' }, status: :unprocessable_entity
  end

    @renegotiation.update!(status: "done")
    render json: { success: true }
  end




  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_renegotiation
    @renegotiation = Renegotiation.find(params[:id])
  end

  def renegotiation_params
    params.require(:renegotiation).permit(:tone, :min_target, :max_target, :thread, :new_price)
  end

  def discount_target_params
    params.permit(:target_discount_percentage, :min_discount_percentage)
  end

  # below is the fill the new renegotiation instance with a min_target and max_target before the user can set it
  def calculate_min_target(product)
    (product.current_price * 0.90).round(2)
  end

  def calculate_max_target(product)
    (product.current_price * 0.95).round(2)
  end
end
