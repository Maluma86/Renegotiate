class RenegotiationsController < ApplicationController

  def confirm_target
    @renegotiation = Renegotiation.find(params[:id])

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

    @available_tones = ['collaborative', 'direct', 'formal', 'urgent']
  end

  def set_target
    @renegotiation = Renegotiation.find(params[:id])

    # Process form data (basic version)
    target_price = params[:target_price]
    selected_tone = params[:tone]

    # For now, just redirect back (we'll add processing later)
    redirect_to renegotiation_path(@renegotiation),
                notice: "Target set to #{target_price} with #{selected_tone} tone"
  end

end
