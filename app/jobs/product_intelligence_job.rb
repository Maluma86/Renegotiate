class ProductIntelligenceJob < ApplicationJob
  queue_as :default

  def perform(renegotiation_id)
    Rails.logger.info "🚀 ProductIntelligenceJob STARTED for renegotiation #{renegotiation_id}"
    
    renegotiation = Renegotiation.find(renegotiation_id)
    product = renegotiation.product
    cache_key = build_cache_key(product)

    intelligence_data = get_or_generate_intelligence(product, cache_key, renegotiation_id)
    store_result_for_ajax(renegotiation_id, intelligence_data)
    cleanup_job_status(renegotiation_id)

    Rails.logger.info "✅ ProductIntelligenceJob completed for renegotiation #{renegotiation_id}"
  rescue StandardError => e
    handle_job_error(renegotiation_id, e)
  end

  private

  def get_or_generate_intelligence(product, cache_key, renegotiation_id)
    intelligence_data = Rails.cache.read(cache_key)

    if intelligence_data.nil?
      intelligence_data = generate_fresh_intelligence(product, cache_key, renegotiation_id)
    else
      Rails.logger.info "💾 Using cached product intelligence for product #{product.id}"
    end

    intelligence_data
  end

  def generate_fresh_intelligence(product, cache_key, renegotiation_id)
    Rails.logger.info "⏳ Generating new product intelligence for product #{product.id}"
    service = ProductIntelligenceService.new
    
    # Step 1: Generate recommendation first (4-5 seconds)
    start_time = Time.current
    Rails.logger.info "[#{Time.current}] 💡 Starting AI recommendation generation..."
    recommendation = service.generate_recommendation(product)
    Rails.logger.info "[#{Time.current}] 📡 Recommendation complete (took #{(Time.current - start_time).round(1)}s)"
    
    # Store recommendation immediately for AJAX polling
    store_partial_result(renegotiation_id, :recommendation, recommendation)
    
    # Step 2: Generate ingredients next (8-10 seconds)
    ingredients_start = Time.current
    Rails.logger.info "[#{Time.current}] 🧪 Starting ingredient analysis..."
    ingredients = service.generate_ingredients_analysis(product)
    Rails.logger.info "[#{Time.current}] 💾 Ingredients complete: #{ingredients&.length || 0} items (took #{(Time.current - ingredients_start).round(1)}s)"
    store_partial_result(renegotiation_id, :ingredients, ingredients)
    
    # Step 3: Generate price drivers (12-14 seconds)
    price_start = Time.current
    Rails.logger.info "[#{Time.current}] 📊 Starting price drivers analysis..."
    price_drivers = service.generate_price_drivers(product)
    Rails.logger.info "[#{Time.current}] 💾 Price drivers complete: #{price_drivers&.length || 0} items (took #{(Time.current - price_start).round(1)}s)"
    
    # Store price drivers as partial for streaming
    store_partial_result(renegotiation_id, :price_drivers, price_drivers)
    
    # Step 4: Generate forecast timeline (16-18 seconds)
    forecast_start = Time.current
    Rails.logger.info "[#{Time.current}] 📈 Starting price forecast analysis..."
    forecast = service.generate_forecast(product)
    Rails.logger.info "[#{Time.current}] 💾 Forecast complete: #{forecast&.length || 0} timeline points (took #{(Time.current - forecast_start).round(1)}s)"
    
    # Store forecast as partial for streaming
    store_partial_result(renegotiation_id, :forecast, forecast)
    
    # Step 5: Generate risk assessment (20-22 seconds)
    risks_start = Time.current
    Rails.logger.info "[#{Time.current}] ⚠️ Starting risk assessment analysis..."
    risks = service.generate_risk_assessment(product)
    Rails.logger.info "[#{Time.current}] 💾 Risk assessment complete: #{risks ? risks.keys.length : 0} categories (took #{(Time.current - risks_start).round(1)}s)"
    
    # Store risks as partial for streaming
    store_partial_result(renegotiation_id, :risks, risks)
    
    # Step 6: Generate negotiation strategies (24-26 seconds)
    strategies_start = Time.current
    Rails.logger.info "[#{Time.current}] 🎯 Starting negotiation strategies analysis..."
    strategies = service.generate_negotiation_strategies(product)
    Rails.logger.info "[#{Time.current}] 💾 Negotiation strategies complete: #{strategies&.length || 0} strategies (took #{(Time.current - strategies_start).round(1)}s)"
    
    # Store strategies as partial for streaming
    store_partial_result(renegotiation_id, :strategies, strategies)
    
    # Build complete intelligence data with all sections
    intelligence_data = {
      recommendation: recommendation,
      ingredients: ingredients,
      forecast: forecast,
      price_drivers: price_drivers,
      risks: risks,
      strategies: strategies
    }

    # Small delay to allow frontend to poll and get partial results
    Rails.logger.info "[#{Time.current}] ⏳ Waiting 2 seconds before storing complete result..."
    sleep(2)

    Rails.cache.write(cache_key, intelligence_data, expires_in: 6.hours)
    Rails.logger.info "[#{Time.current}] 💾 Cached complete product intelligence for product #{product.id}"
    Rails.logger.info "[#{Time.current}] ⏱️ Total generation time: #{(Time.current - start_time).round(1)}s"

    intelligence_data
  end

  def store_result_for_ajax(renegotiation_id, intelligence_data)
    result_key = "product_intel_result_#{renegotiation_id}"
    Rails.cache.write(result_key, intelligence_data, expires_in: 1.hour)
    Rails.logger.info "[#{Time.current}] 📦 Stored complete result for AJAX polling"
  end

  def store_partial_result(renegotiation_id, section, data)
    partial_key = "product_intel_partial_#{renegotiation_id}"
    partial_data = Rails.cache.read(partial_key) || {}
    partial_data[section] = data
    partial_data[:last_updated] = Time.current
    Rails.cache.write(partial_key, partial_data, expires_in: 1.hour)
    Rails.logger.info "[#{Time.current}] 💾 Stored partial result for section: #{section}"
  end

  def cleanup_job_status(renegotiation_id)
    job_status_key = "product_intel_job_#{renegotiation_id}"
    Rails.cache.delete(job_status_key)
  end

  def handle_job_error(renegotiation_id, error)
    Rails.logger.error "ProductIntelligenceJob failed for renegotiation #{renegotiation_id}: #{error.message}"

    error_result = build_error_result
    store_result_for_ajax(renegotiation_id, error_result)
    cleanup_job_status(renegotiation_id)

    raise error
  end

  def build_error_result
    {
      recommendation: "AI analysis temporarily unavailable. Please refresh the page to try again.",
      forecast: nil,
      ingredients: nil,
      risks: nil,
      strategies: nil,
      error: true
    }
  end

  # Turbo Stream broadcast method - COMMENTED OUT (using AJAX polling instead)
  # def broadcast_recommendation(renegotiation_id, recommendation)
  #   # Use same Turbo Stream pattern as ChatbotJob
  #   Turbo::StreamsChannel.broadcast_update_to(
  #     "ai_recommendation_#{renegotiation_id}",
  #     target: "ai-content",
  #     partial: "shared/ai_recommendation_content",
  #     locals: { recommendation: recommendation }
  #   )
  #   Rails.logger.info "📺 Broadcasted AI recommendation via Turbo Stream for renegotiation #{renegotiation_id}"
  # end

  def build_cache_key(product)
    "product_intel_#{product.id}_#{product.updated_at.to_i}_#{product.current_price.to_i}"
  end
end
