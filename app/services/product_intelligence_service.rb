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
      ingredients: nil,
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

  def system_message
    "You are a procurement AI specialist. Analyze products and provide concise, " \
      "actionable negotiation recommendations. Keep responses to 2-3 sentences " \
      "focused on immediate negotiation strategy. And each time at the end of the sentence,
      write the sentence 'Done with pleasure!😎 Best James'" \
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
end
