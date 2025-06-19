class ProductIntelligenceJob < ApplicationJob
  queue_as :default

  def perform(renegotiation_id)
    renegotiation = Renegotiation.find(renegotiation_id)
    product = renegotiation.product
    cache_key = build_cache_key(product)

    # First: Stream recommendation immediately for faster user feedback
    stream_recommendation_if_needed(product, renegotiation_id)

    # Second: Stream forecast after recommendation
    stream_forecast_if_needed(product, renegotiation_id)

    # Third: Stream ingredients after forecast
    stream_ingredients_if_needed(product, renegotiation_id)

    # Fourth: Stream price drivers after ingredients
    stream_price_drivers_if_needed(product, renegotiation_id)

    # Fifth: Stream risks after price drivers
    stream_risks_if_needed(product, renegotiation_id)

    # Sixth: Stream strategies after risks
    stream_strategies_if_needed(product, renegotiation_id)

    # Then: Continue with full analysis as before
    intelligence_data = get_or_generate_intelligence(product, cache_key)
    store_result_for_ajax(renegotiation_id, intelligence_data)
    cleanup_job_status(renegotiation_id)

    Rails.logger.info "ProductIntelligenceJob completed for renegotiation #{renegotiation_id}"
  rescue StandardError => e
    handle_job_error(renegotiation_id, e)
  end

  private

  def stream_recommendation_if_needed(product, renegotiation_id)
    # Check if recommendation is already cached (avoid duplicate work)
    recommendation_key = "product_intel_#{renegotiation_id}_recommendation"
    return if Rails.cache.exist?(recommendation_key)

    # Stream the recommendation immediately
    service = ProductIntelligenceService.new
    service.stream_recommendation(product, renegotiation_id)
  rescue StandardError => e
    Rails.logger.error "Failed to stream recommendation for renegotiation #{renegotiation_id}: #{e.message}"
    # Don't fail the whole job if streaming fails - continue with normal process
  end

  def stream_forecast_if_needed(product, renegotiation_id)
    # Check if forecast is already cached (avoid duplicate work)
    forecast_key = "product_intel_#{renegotiation_id}_forecast"
    return if Rails.cache.exist?(forecast_key)

    # Stream the forecast
    service = ProductIntelligenceService.new
    service.stream_forecast(product, renegotiation_id)
  rescue StandardError => e
    Rails.logger.error "Failed to stream forecast for renegotiation #{renegotiation_id}: #{e.message}"
    # Don't fail the whole job if streaming fails - continue with normal process
  end

  def stream_ingredients_if_needed(product, renegotiation_id)
    # Check if ingredients is already cached (avoid duplicate work)
    ingredients_key = "product_intel_#{renegotiation_id}_ingredients"
    return if Rails.cache.exist?(ingredients_key)

    # Stream the ingredients
    service = ProductIntelligenceService.new
    service.stream_ingredients(product, renegotiation_id)
  rescue StandardError => e
    Rails.logger.error "Failed to stream ingredients for renegotiation #{renegotiation_id}: #{e.message}"
    # Don't fail the whole job if streaming fails - continue with normal process
  end

  def stream_price_drivers_if_needed(product, renegotiation_id)
    # Check if price drivers is already cached (avoid duplicate work)
    price_drivers_key = "product_intel_#{renegotiation_id}_price_drivers"
    return if Rails.cache.exist?(price_drivers_key)

    # Stream the price drivers
    service = ProductIntelligenceService.new
    service.stream_price_drivers(product, renegotiation_id)
  rescue StandardError => e
    Rails.logger.error "Failed to stream price drivers for renegotiation #{renegotiation_id}: #{e.message}"
    # Don't fail the whole job if streaming fails - continue with normal process
  end

  def stream_risks_if_needed(product, renegotiation_id)
    # Check if risks is already cached (avoid duplicate work)
    risks_key = "product_intel_#{renegotiation_id}_risks"
    return if Rails.cache.exist?(risks_key)

    # Stream the risks
    service = ProductIntelligenceService.new
    service.stream_risks(product, renegotiation_id)
  rescue StandardError => e
    Rails.logger.error "Failed to stream risks for renegotiation #{renegotiation_id}: #{e.message}"
    # Don't fail the whole job if streaming fails - continue with normal process
  end

  def stream_strategies_if_needed(product, renegotiation_id)
    # Check if strategies is already cached (avoid duplicate work)
    strategies_key = "product_intel_#{renegotiation_id}_strategies"
    return if Rails.cache.exist?(strategies_key)

    # Stream the strategies
    service = ProductIntelligenceService.new
    service.stream_strategies(product, renegotiation_id)
  rescue StandardError => e
    Rails.logger.error "Failed to stream strategies for renegotiation #{renegotiation_id}: #{e.message}"
    # Don't fail the whole job if streaming fails - continue with normal process
  end

  def get_or_generate_intelligence(product, cache_key)
    intelligence_data = Rails.cache.read(cache_key)

    if intelligence_data.nil?
      intelligence_data = generate_fresh_intelligence(product, cache_key)
    else
      Rails.logger.info "Using cached product intelligence for product #{product.id}"
    end

    intelligence_data
  end

  def generate_fresh_intelligence(product, cache_key)
    Rails.logger.info "Generating new product intelligence for product #{product.id}"
    service = ProductIntelligenceService.new
    intelligence_data = service.analyze_product(product)

    Rails.cache.write(cache_key, intelligence_data, expires_in: 6.hours)
    Rails.logger.info "Cached product intelligence for product #{product.id}"

    intelligence_data
  end

  def store_result_for_ajax(renegotiation_id, intelligence_data)
    result_key = "product_intel_result_#{renegotiation_id}"
    Rails.logger.info "💾 Job Storage - Storing data at cache key: #{result_key}"
    Rails.cache.write(result_key, intelligence_data, expires_in: 1.hour)
    Rails.logger.info "💾 Job Storage - Data stored successfully with keys: #{intelligence_data.keys}" if intelligence_data.is_a?(Hash)
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

  def build_cache_key(product)
    "product_intel_#{product.id}_#{product.updated_at.to_i}_#{product.current_price.to_i}"
  end
end
