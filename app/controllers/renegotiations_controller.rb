class RenegotiationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: %i[new create]
  before_action :set_renegotiation, only: %i[show confirm_target set_target save_discount_targets]

  def show
    # we already have @renegotiation from set_renegotiation
    @product  = @renegotiation.product
    @supplier = @product.supplier
    @questions = @renegotiation.questions.order(:created_at) # LS changed this to try to fix @questions = current_user.questions before
    @question = Question.new # for form
  end

  def new
    # Use Product model method for consistent company-level checking
    if @product.has_ongoing_renegotiation?(current_user)
      # Find the existing renegotiation using the same company-level logic
      @renegotiation = @product.renegotiations
                              .joins(:buyer)
                              .find_by(users: { company_name: current_user.company_name }, 
                                     status: "Ongoing")
      
      Rails.logger.info "Found existing renegotiation with ID=#{@renegotiation.id} (created by user #{@renegotiation.buyer_id}), reusing it"
      redirect_to confirm_target_renegotiation_path(@renegotiation)
    else
      # Create new renegotiation only if none exists for this company
      @renegotiation = @product.renegotiations.new(
        buyer: current_user,
        supplier_id: @product.supplier_id,
        status: "Ongoing",
        min_target: calculate_min_target(@product),
        max_target: calculate_max_target(@product),
        tone: "collaborative"
      )

      if @renegotiation.save
        Rails.logger.info "Successfully created new renegotiation with ID=#{@renegotiation.id} for company #{current_user.company_name}"
        redirect_to confirm_target_renegotiation_path(@renegotiation)
      else
        Rails.logger.error "Failed to save renegotiation: #{@renegotiation.errors.full_messages}"
        redirect_to product_path(@product), alert: "Failed to create renegotiation"
      end
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
      reasoning: "Test data - AI integration coming in task 7.10"
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
