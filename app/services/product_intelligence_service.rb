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
      forecast: generate_forecast(product),
      ingredients: generate_ingredients_analysis(product),
      price_drivers: generate_price_drivers(product),
      risks: generate_risks(product),
      strategies: generate_strategies(product)
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

  def generate_risks(product)
    prompt = build_risks_prompt(product)

    Rails.logger.info "Starting risk analysis for product: #{product.name}"

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: build_risks_messages(prompt),
        temperature: 0.7,
        max_tokens: 700
      }
    )

    content = response.dig("choices", 0, "message", "content")
    Rails.logger.info "Raw risks response: #{content}"

    return nil unless content

    # Strip markdown formatting if present
    clean_content = content.strip
    if clean_content.start_with?('```json')
      clean_content = clean_content.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
    elsif clean_content.start_with?('```')
      clean_content = clean_content.gsub(/^```\s*/, '').gsub(/\s*```$/, '')
    end

    Rails.logger.info "Cleaned risks content: #{clean_content}"

    parsed = JSON.parse(clean_content)
    
    # Ensure we have the expected structure
    result = {
      geopolitical: {
        level: parsed.dig("geopolitical", "level") || "HIGH",
        items: parsed.dig("geopolitical", "items") || []
      },
      product_specific: {
        level: parsed.dig("product_specific", "level") || "MEDIUM",
        items: parsed.dig("product_specific", "items") || []
      },
      supply_chain: {
        level: parsed.dig("supply_chain", "level") || "LOW",
        items: parsed.dig("supply_chain", "items") || []
      }
    }

    # Ensure each category has exactly 3 items
    result.each do |category, data|
      data[:items] = data[:items].first(3)
      while data[:items].length < 3
        data[:items] << "Risk analysis pending"
      end
    end

    Rails.logger.info "Final risks result: #{result}"
    result
  rescue JSON::ParserError => e
    Rails.logger.error "Risks JSON parsing error: #{e.message}. Raw content: #{content}"
    nil
  rescue Faraday::BadRequestError => e
    Rails.logger.error "Risks OpenAI API 400 error: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Risks analysis error: #{e.message}"
    nil
  end

  def generate_strategies(product)
    prompt = build_strategies_prompt(product)

    Rails.logger.info "Starting negotiation strategies analysis for product: #{product.name}"

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: build_strategies_messages(prompt),
        temperature: 0.7,
        max_tokens: 800
      }
    )

    content = response.dig("choices", 0, "message", "content")
    Rails.logger.info "Raw strategies response: #{content}"

    return nil unless content

    # Strip markdown formatting if present
    clean_content = content.strip
    if clean_content.start_with?('```json')
      clean_content = clean_content.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
    elsif clean_content.start_with?('```')
      clean_content = clean_content.gsub(/^```\s*/, '').gsub(/\s*```$/, '')
    end

    Rails.logger.info "Cleaned strategies content: #{clean_content}"

    parsed = JSON.parse(clean_content)
    
    # Extract strategies and pro tip
    strategies = parsed["strategies"] || []
    strategies = strategies.is_a?(Array) ? strategies : []
    
    # Ensure we have exactly 5 strategies
    result_strategies = strategies.first(5).map do |strategy|
      {
        title: strategy["title"] || "Strategy",
        description: strategy["description"] || "Analysis pending"
      }
    end
    
    # Fill in missing strategies if needed
    while result_strategies.length < 5
      result_strategies << {
        title: "Additional Strategy",
        description: "Further analysis recommended"
      }
    end

    result = {
      strategies: result_strategies,
      pro_tip: parsed["pro_tip"] || "Monitor market conditions closely for optimal negotiation timing."
    }

    Rails.logger.info "Final strategies result: #{result}"
    result
  rescue JSON::ParserError => e
    Rails.logger.error "Strategies JSON parsing error: #{e.message}. Raw content: #{content}"
    nil
  rescue Faraday::BadRequestError => e
    Rails.logger.error "Strategies OpenAI API 400 error: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Strategies analysis error: #{e.message}"
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
        max_tokens: 600
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
    
    # Extract periods and overall trend
    periods_data = parsed["periods"] || parsed
    periods_data = periods_data.is_a?(Array) ? periods_data : []
    
    # Generate month labels starting from current month
    current_month = Date.current
    periods = periods_data.first(6).map.with_index do |period, index|
      month_date = current_month + index.months
      {
        label: month_date.strftime("%b"),
        value: [(period["value"] || 50).to_f, 100].min.round, # Cap at 100%
        trend: (period["trend"] || 0).to_f
      }
    end

    # Calculate overall trend
    total_change = periods.sum { |p| p[:trend] }
    avg_change = periods.any? ? (total_change / periods.length).round(1) : 0
    
    trend_description = if avg_change > 5
                          "upward trend expected"
                        elsif avg_change < -5
                          "downward trend expected"
                        else
                          "stable prices expected"
                        end

    result = {
      title: "6-Month Price Forecast",
      periods: periods,
      overall_trend: {
        value: avg_change,
        description: trend_description
      }
    }

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
    "You are a procurement market analyst specializing in price forecasting. " \
      "Return ONLY a valid JSON object with a 'periods' array containing 6 monthly forecasts. " \
      "Each period must have: value (relative height 10-100), trend (percentage change -30 to +30). " \
      "Base forecasts on realistic market conditions. " \
      "Return ONLY a valid JSON object. Do NOT wrap in markdown, triple backticks, or add any formatting."
  end

  def build_forecast_prompt(product)
    <<~PROMPT
      Generate a 6-month price forecast for this product based on market analysis:

      Product: #{product.name}
      Category: #{product.category || 'Not specified'}
      Description: #{product.description || 'No description available'}
      Current Price: €#{product.current_price}

      Analyze market trends and create a 6-month forecast with:
      - Each month: value (chart height 10-100), trend (price change percentage -30 to +30)
      - Consider seasonal factors, supply chain conditions, and market dynamics
      - Base on realistic market conditions for the product type

      Return a JSON object with 'periods' array containing 6 months of forecast data.
      Example format: {"periods": [{"value": 60, "trend": 5}, {"value": 65, "trend": 8}, ...]}
    PROMPT
  end

  def build_risks_messages(prompt)
    [
      {
        role: "system",
        content: risks_system_message
      },
      {
        role: "user",
        content: prompt
      }
    ]
  end

  def risks_system_message
    "You are a procurement risk analyst specializing in supply chain and market risk assessment. " \
      "Return ONLY a valid JSON object with three risk categories: geopolitical, product_specific, supply_chain. " \
      "Each category must have: level (HIGH/MEDIUM/LOW), items (array of 3 specific risk descriptions). " \
      "Focus on current, real-world risks relevant to the product and its supply chain. " \
      "Return ONLY a valid JSON object. Do NOT wrap in markdown, triple backticks, or add any formatting."
  end

  def build_risks_prompt(product)
    <<~PROMPT
      Analyze current risks for this product across three categories:

      Product: #{product.name}
      Category: #{product.category || 'Not specified'}
      Description: #{product.description || 'No description available'}
      Current Price: €#{product.current_price}

      Generate risk assessment with:

      1. Geopolitical Risks: Current political/regulatory risks affecting this product's supply chain
      2. Product-Specific Risks: Risks specific to this product type (materials, production, quality)
      3. Supply Chain Risks: Logistics, transportation, and distribution risks

      For each category provide:
      - level: HIGH/MEDIUM/LOW based on actual risk assessment
      - items: Array of 3 specific, current risk factors (not generic)

      Format: {"geopolitical": {"level": "HIGH", "items": ["Risk 1", "Risk 2", "Risk 3"]}, ...}
    PROMPT
  end

  def build_strategies_messages(prompt)
    [
      {
        role: "system",
        content: strategies_system_message
      },
      {
        role: "user",
        content: prompt
      }
    ]
  end

  def strategies_system_message
    "You are an expert procurement negotiation strategist. " \
      "Return ONLY a valid JSON object with 'strategies' array (5 items) and 'pro_tip' string. " \
      "Each strategy must have: title (action-oriented phrase), description (specific explanation). " \
      "Focus on actionable, time-sensitive strategies based on current market conditions. " \
      "Return ONLY a valid JSON object. Do NOT wrap in markdown, triple backticks, or add any formatting."
  end

  def build_strategies_prompt(product)
    supplier_info = if product.supplier
                      "Supplier: #{product.supplier.company_name}"
                    else
                      "Supplier: Not specified"
                    end

    <<~PROMPT
      Create 5 actionable negotiation strategies for this procurement scenario:

      Product: #{product.name}
      Category: #{product.category || 'Not specified'}
      Description: #{product.description || 'No description available'}
      Current Price: €#{product.current_price}
      #{supplier_info}

      Generate negotiation strategies considering:
      - Current market conditions and trends
      - Product-specific leverage points
      - Timing opportunities
      - Risk mitigation tactics
      - Value optimization approaches

      Return a JSON object with:
      1. "strategies": Array of 5 strategies, each with "title" and "description"
      2. "pro_tip": One insider tip for maximum negotiation leverage

      Make strategies specific, actionable, and time-aware. Avoid generic advice.
    PROMPT
  end
end
