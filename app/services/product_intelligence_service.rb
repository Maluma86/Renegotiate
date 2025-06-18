class ProductIntelligenceService
  def initialize
    @client = OpenAI::Client.new(
      access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"),
      request_timeout: 300
    )
  end

  def analyze_product(product)
    {
      recommendation: generate_recommendation(product),
      forecast: nil,
      ingredients: generate_ingredients_analysis(product),
      risks: nil,
      strategies: nil
    }
  end

  def generate_recommendation(product)
    prompt = build_recommendation_prompt(product)

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: build_messages(prompt),
        temperature: 0.7,
        max_tokens: 200
      }
    )

    response.dig("choices", 0, "message", "content") ||
      "Unable to generate recommendation at this time."
  rescue StandardError => e
    Rails.logger.error "ProductIntelligenceService error: #{e.message}"
    "AI analysis temporarily unavailable. Please try again later."
  end

  def generate_ingredients_analysis(product)
    prompt = build_ingredients_prompt(product)

    Rails.logger.info "Starting ingredient analysis for product: #{product.name}"

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: build_ingredients_messages(prompt),
        temperature: 0.7,
        max_tokens: 10_000
      }
    )

    # Log token usage
    if response["usage"]
      Rails.logger.info "Token usage - Prompt: #{response['usage']['prompt_tokens']}, " \
                        "Completion: #{response['usage']['completion_tokens']}, " \
                        "Total: #{response['usage']['total_tokens']}"
    end

    content = response.dig("choices", 0, "message", "content")
    Rails.logger.info "AI Response content: #{content}"

    return nil unless content

    # Strip markdown formatting if present
    clean_content = content.strip
    if clean_content.start_with?('```json')
      clean_content = clean_content.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
    elsif clean_content.start_with?('```')
      clean_content = clean_content.gsub(/^```\s*/, '').gsub(/\s*```$/, '')
    end

    Rails.logger.info "Cleaned content: #{clean_content}"

    # Parse JSON response
    parsed = JSON.parse(clean_content)
    Rails.logger.info "Parsed JSON: #{parsed}"

    # Ensure we have an array of ingredients
    ingredients = parsed.is_a?(Array) ? parsed : (parsed["ingredients"] || [])

    # Take only top 5 and ensure proper format
    result = ingredients.first(5).map do |ing|
      {
        name: ing["name"] || "Unknown",
        percentage: ing["percentage"] || 0,
        origin: ing["origin"] || "Not specified",
        price_trend: ing["price_trend"] || 0,
        trend_direction: ing["trend_direction"] || "stable",
        risk_level: ing["risk_level"] || "MEDIUM"
      }
    end

    Rails.logger.info "Final ingredients result: #{result}"
    result
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parsing error: #{e.message}. Raw content: #{content}"
    nil
  rescue Faraday::BadRequestError => e
    Rails.logger.error "OpenAI API 400 error: #{e.message}"
    Rails.logger.error "Response details: #{e.response}"
    nil
  rescue StandardError => e
    Rails.logger.error "Ingredients analysis error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  private

  def build_messages(prompt)
    [
      {
        role: "system",
        content: system_message
      },
      {
        role: "user",
        content: prompt
      }
    ]
  end

  def build_ingredients_messages(prompt)
    [
      {
        role: "system",
        content: ingredients_system_message
      },
      {
        role: "user",
        content: prompt
      }
    ]
  end

  def system_message
    "You are a procurement AI specialist. Analyze products and provide concise, " \
      "actionable negotiation recommendations. Keep responses to 2-3 sentences " \
      "focused on immediate negotiation strategy. And each time at the end of the sentence,
      write the sentence 'Done with pleasure!😎 Best James'" \
  end

  def ingredients_system_message
    "You are a procurement specialist analyzing product composition. " \
      "Return ONLY a valid JSON array with exactly 5 ingredients/components. " \
      "Each object must have: name, percentage, origin, price_trend (number -100 to 100), " \
      "trend_direction (up/down/stable), risk_level (HIGH/MEDIUM/LOW). " \
      "Return ONLY a valid JSON array. Do NOT wrap the output in markdown, triple backticks, or add any formatting."
  end

  def build_recommendation_prompt(product)
    supplier_info = if product.supplier
                      "Supplier: #{product.supplier.company_name}"
                    else
                      "Supplier: Not specified"
                    end

    build_prompt_content(product, supplier_info)
  end

  def build_prompt_content(product, supplier_info)
    <<~PROMPT
      Analyze this procurement scenario and provide a concise negotiation recommendation:

      Product: #{product.name}
      Category: #{product.category || 'Not specified'}
      Description: #{product.description || 'No description available'}
      Current Price: €#{product.current_price}
      #{supplier_info}

      Provide a 2-3 sentence recommendation focusing on:
      1. Key negotiation leverage points
      2. Optimal timing considerations
      3. Realistic discount expectations

      Be specific and actionable for immediate use in negotiations.
    PROMPT
  end

  def build_ingredients_prompt(product)
    <<~PROMPT
      Analyze the composition of this product and identify the top 5 ingredients or components:

      Product: #{product.name}
      Category: #{product.category || 'Not specified'}
      Description: #{product.description || 'No description available'}

      Based on the product type, provide the 5 most significant ingredients/components with:
      - Realistic percentage composition (must total 100% or less)
      - Typical origin countries/regions
      - Current market price trend (-100 to +100, where negative is decreasing)
      - Risk assessment based on supply chain factors

      For non-food products, list the main components or materials.
      Return ONLY a JSON array with the ingredient data.
    PROMPT
  end
end
