class RenegotiationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:new, :create]
  before_action :set_renegotiation, only: [:confirm_target, :set_target]

  def new
    @renegotiation = @product.renegotiations.build
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
end
