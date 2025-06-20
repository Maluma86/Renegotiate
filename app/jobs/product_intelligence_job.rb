class ProductIntelligenceJob < ApplicationJob
  queue_as :default

  def perform(renegotiation_id)
    renegotiation = Renegotiation.find(renegotiation_id)
    product = renegotiation.product
    cache_key = build_cache_key(product)

    intelligence_data = get_or_generate_intelligence(product, cache_key)
    store_result_for_ajax(renegotiation_id, intelligence_data)
    cleanup_job_status(renegotiation_id)

    Rails.logger.info "ProductIntelligenceJob completed for renegotiation #{renegotiation_id}"
  rescue StandardError => e
    handle_job_error(renegotiation_id, e)
  end

  private

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
    Rails.cache.write(result_key, intelligence_data, expires_in: 1.hour)
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
