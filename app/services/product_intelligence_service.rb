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
      ingredients: generate_ingredients_analysis(product),
      forecast: generate_forecast(product),
      price_drivers: generate_price_drivers(product),
      risks: generate_risk_assessment(product),
      strategies: generate_negotiation_strategies(product)
    }
  end

  def generate_recommendation(product)
    prompt = build_recommendation_prompt(product)

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: build_messages(prompt),
        temperature: 0.7,
        max_tokens: 10_000
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

  def generate_price_drivers(product)
    prompt = build_price_drivers_prompt(product)

    Rails.logger.info "Starting price drivers analysis for product: #{product.name}"

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: build_price_drivers_messages(prompt),
        temperature: 0.7,
        max_tokens: 800
      }
    )

    content = response.dig("choices", 0, "message", "content")
    Rails.logger.info "Raw price drivers response: #{content}"

    return nil unless content

    # Strip markdown formatting if present
    clean_content = content.strip
    if clean_content.start_with?('```json')
      clean_content = clean_content.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
    elsif clean_content.start_with?('```')
      clean_content = clean_content.gsub(/^```\s*/, '').gsub(/\s*```$/, '')
    end

    Rails.logger.info "Cleaned price drivers content: #{clean_content}"

    parsed = JSON.parse(clean_content)
    drivers = parsed.is_a?(Array) ? parsed : (parsed["price_drivers"] || [])

    result = drivers.first(5).map do |driver|
      level = driver["level"] || "medium"
      icon = case level.downcase
             when "high" then "🔴"
             when "low" then "🟢"
             else "🟡"
             end

      {
        level: level,
        icon: icon,
        description: driver["description"] || "Market analysis not available"
      }
    end

    Rails.logger.info "Final price drivers result: #{result}"
    result
  rescue JSON::ParserError => e
    Rails.logger.error "Price drivers JSON parsing error: #{e.message}. Raw content: #{content}"
    nil
  rescue Faraday::BadRequestError => e
    Rails.logger.error "Price drivers OpenAI API 400 error: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Price drivers analysis error: #{e.message}"
    nil
  end

  def generate_forecast(product)
    prompt = build_forecast_prompt(product)

    Rails.logger.info "Starting price forecast analysis for product: #{product.name}"

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: build_forecast_messages(prompt),
        temperature: 0.7,
        max_tokens: 1200
      }
    )

    content = response.dig("choices", 0, "message", "content")
    Rails.logger.info "Raw forecast response: #{content}"

    return nil unless content

    # Strip markdown formatting if present
    clean_content = content.strip
    if clean_content.start_with?('```json')
      clean_content = clean_content.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
    elsif clean_content.start_with?('```')
      clean_content = clean_content.gsub(/^```\s*/, '').gsub(/\s*```$/, '')
    end

    Rails.logger.info "Cleaned forecast content: #{clean_content}"

    parsed = JSON.parse(clean_content)
    forecast_data = parsed.is_a?(Array) ? parsed : (parsed["forecast"] || [])

    # Ensure we have timeline points for the next 6-12 months
    result = forecast_data.first(6).map do |point|
      {
        month: point["month"] || "Unknown",
        price_change: point["price_change"] || 0,
        confidence: point["confidence"] || 50,
        factors: point["factors"] || "Market analysis not available"
      }
    end

    Rails.logger.info "Final forecast result: #{result}"
    result
  rescue JSON::ParserError => e
    Rails.logger.error "Forecast JSON parsing error: #{e.message}. Raw content: #{content}"
    nil
  rescue Faraday::BadRequestError => e
    Rails.logger.error "Forecast OpenAI API 400 error: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Forecast analysis error: #{e.message}"
    nil
  end

  def generate_risk_assessment(product)
    prompt = build_risk_assessment_prompt(product)

    Rails.logger.info "Starting risk assessment analysis for product: #{product.name}"

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: build_risk_assessment_messages(prompt),
        temperature: 0.7,
        max_tokens: 1000
      }
    )

    content = response.dig("choices", 0, "message", "content")
    Rails.logger.info "Raw risk assessment response: #{content}"

    return nil unless content

    # Strip markdown formatting if present
    clean_content = content.strip
    if clean_content.start_with?('```json')
      clean_content = clean_content.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
    elsif clean_content.start_with?('```')
      clean_content = clean_content.gsub(/^```\s*/, '').gsub(/\s*```$/, '')
    end

    Rails.logger.info "Cleaned risk assessment content: #{clean_content}"

    parsed = JSON.parse(clean_content)
    risk_data = parsed.is_a?(Hash) ? parsed : {}

    # Ensure we have the expected structure
    result = {
      geopolitical: risk_data["geopolitical"] || [],
      product_specific: risk_data["product_specific"] || [],
      supply_chain: risk_data["supply_chain"] || []
    }

    Rails.logger.info "Final risk assessment result: #{result}"
    result
  rescue JSON::ParserError => e
    Rails.logger.error "Risk assessment JSON parsing error: #{e.message}. Raw content: #{content}"
    nil
  rescue Faraday::BadRequestError => e
    Rails.logger.error "Risk assessment OpenAI API 400 error: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Risk assessment analysis error: #{e.message}"
    nil
  end

  def generate_negotiation_strategies(product)
    prompt = build_negotiation_strategies_prompt(product)

    Rails.logger.info "Starting negotiation strategies analysis for product: #{product.name}"

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: build_negotiation_strategies_messages(prompt),
        temperature: 0.7,
        max_tokens: 1000
      }
    )

    content = response.dig("choices", 0, "message", "content")
    Rails.logger.info "Raw negotiation strategies response: #{content}"

    return nil unless content

    # Strip markdown formatting if present
    clean_content = content.strip
    if clean_content.start_with?('```json')
      clean_content = clean_content.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
    elsif clean_content.start_with?('```')
      clean_content = clean_content.gsub(/^```\s*/, '').gsub(/\s*```$/, '')
    end

    Rails.logger.info "Cleaned negotiation strategies content: #{clean_content}"

    parsed = JSON.parse(clean_content)
    strategies_data = parsed.is_a?(Array) ? parsed : (parsed["strategies"] || [])

    # Ensure we have actionable strategies
    result = strategies_data.first(5).map do |strategy|
      {
        title: strategy["title"] || "Strategy",
        description: strategy["description"] || "Strategy analysis not available",
        priority: strategy["priority"] || "medium",
        timeframe: strategy["timeframe"] || "immediate"
      }
    end

    Rails.logger.info "Final negotiation strategies result: #{result}"
    result
  rescue JSON::ParserError => e
    Rails.logger.error "Negotiation strategies JSON parsing error: #{e.message}. Raw content: #{content}"
    nil
  rescue Faraday::BadRequestError => e
    Rails.logger.error "Negotiation strategies OpenAI API 400 error: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Negotiation strategies analysis error: #{e.message}"
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

  def build_price_drivers_messages(prompt)
    [
      {
        role: "system",
        content: price_drivers_system_message
      },
      {
        role: "user",
        content: prompt
      }
    ]
  end

  def price_drivers_system_message
    "You are a procurement market analyst. Return ONLY a valid JSON array with 3-5 key price drivers. " \
      "Each object must have: level (high/medium/low), description (ingredient/material: reason). " \
      "Focus on current market conditions affecting the product's main components. " \
      "Return ONLY a valid JSON array. Do NOT wrap in markdown, triple backticks, or add any formatting."
  end

  def build_price_drivers_prompt(product)
    <<~PROMPT
      Analyze current market price drivers for this product's key components:

      Product: #{product.name}
      Category: #{product.category || 'Not specified'}
      Description: #{product.description || 'No description available'}

      Identify 3-5 current market factors affecting the price of this product's main ingredients/materials:
      - Level: high/medium/low impact on pricing
      - Description: Format as "Component: Market condition/reason"

      Focus on real market conditions like supply disruptions, weather, regulations, geopolitical factors.
      Return ONLY a JSON array with the price driver data.
    PROMPT
  end

  def build_forecast_messages(prompt)
    [
      {
        role: "system",
        content: forecast_system_message
      },
      {
        role: "user",
        content: prompt
      }
    ]
  end

  def forecast_system_message
    "You are a procurement market forecasting analyst. Return ONLY a valid JSON array with 6 monthly price forecast points. " \
      "Each object must have: month (format: 'Jan 2025'), price_change (percentage -30 to +30), " \
      "confidence (1-100), factors (brief reason for price change). " \
      "Base predictions on seasonal patterns, market trends, and supply chain analysis. " \
      "Return ONLY a valid JSON array. Do NOT wrap in markdown, triple backticks, or add any formatting."
  end

  def build_forecast_prompt(product)
    current_date = Date.current
    next_6_months = (1..6).map { |i| current_date.next_month(i).strftime('%b %Y') }

    <<~PROMPT
      Create a 6-month price forecast timeline for this product based on market analysis:

      Product: #{product.name}
      Category: #{product.category || 'Not specified'}
      Description: #{product.description || 'No description available'}
      Current Price: €#{product.current_price}

      Forecast the next 6 months (#{next_6_months.join(', ')}):
      - month: Format as "Jan 2025"
      - price_change: Expected percentage change from current price (-30 to +30)
      - confidence: Your confidence level in this prediction (1-100)
      - factors: Brief explanation of key factors driving this price change

      Consider seasonal patterns, supply chain trends, market conditions, and economic factors.
      Return ONLY a JSON array with 6 monthly forecast points.
    PROMPT
  end

  def build_risk_assessment_messages(prompt)
    [
      {
        role: "system",
        content: risk_assessment_system_message
      },
      {
        role: "user",
        content: prompt
      }
    ]
  end

  def risk_assessment_system_message
    "You are a procurement risk analyst. Return ONLY a valid JSON object with 3 risk categories. " \
      "Structure: {\"geopolitical\": [{\"level\": \"high/medium/low\", \"description\": \"risk description\"}], " \
      "\"product_specific\": [...], \"supply_chain\": [...]}. " \
      "Each category should have 2-3 relevant risks. " \
      "Return ONLY a valid JSON object. Do NOT wrap in markdown, triple backticks, or add any formatting."
  end

  def build_risk_assessment_prompt(product)
    <<~PROMPT
      Analyze procurement risks for this product across three categories:

      Product: #{product.name}
      Category: #{product.category || 'Not specified'}
      Description: #{product.description || 'No description available'}
      Current Price: €#{product.current_price}

      Analyze risks in these categories:
      1. Geopolitical: Political events, trade wars, sanctions, elections affecting sourcing regions
      2. Product-Specific: Industry-specific risks, technology changes, regulatory changes
      3. Supply Chain: Transportation, logistics, supplier stability, inventory risks

      For each risk:
      - level: high/medium/low impact on procurement
      - description: Brief explanation of the risk and its impact

      Return ONLY a JSON object with the three risk categories.
    PROMPT
  end

  def build_negotiation_strategies_messages(prompt)
    [
      {
        role: "system",
        content: negotiation_strategies_system_message
      },
      {
        role: "user",
        content: prompt
      }
    ]
  end

  def negotiation_strategies_system_message
    "You are a procurement negotiation strategist. Return ONLY a valid JSON array with 4-5 actionable strategies. " \
      "Each strategy must have: title (action-oriented), description (specific tactics), " \
      "priority (high/medium/low), timeframe (immediate/short-term/long-term). " \
      "Focus on practical, implementable negotiation tactics based on market conditions. " \
      "Return ONLY a valid JSON array. Do NOT wrap in markdown, triple backticks, or add any formatting."
  end

  def build_negotiation_strategies_prompt(product)
    <<~PROMPT
      Develop specific negotiation strategies for this procurement scenario:

      Product: #{product.name}
      Category: #{product.category || 'Not specified'}
      Description: #{product.description || 'No description available'}
      Current Price: €#{product.current_price}

      Create 4-5 actionable negotiation strategies considering:
      - Current market conditions and trends
      - Supplier dynamics and market position
      - Timing advantages and seasonal factors
      - Volume leverage and contract terms
      - Alternative sourcing options

      For each strategy:
      - title: Clear, action-oriented strategy name
      - description: Specific tactics and talking points
      - priority: high/medium/low importance
      - timeframe: immediate/short-term/long-term implementation

      Return ONLY a JSON array with negotiation strategies.
    PROMPT
  end
end
