class ChatbotJob < ApplicationJob
  queue_as :default

  def perform(question)
    @question = question
    chatgpt_response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: questions_formatted_for_openai # to code as private method
      }
    )
    new_content = chatgpt_response["choices"][0]["message"]["content"]

    question.update(ai_answer: new_content)
    Turbo::StreamsChannel.broadcast_update_to(
      "question_#{@question.id}",
      target: "question_#{@question.id}",
      partial: "renegotiations/question", locals: { question: question })
  end

  private

  def client
    @client ||= OpenAI::Client.new
  end


  def questions_formatted_for_openai
    # if it breaks, delete the lines with "**"
    #        **Minimum acceptable price: #{@question.renegotiation.min_target}
    #    **Maximum acceptable price: #{@renegotiation.max_target}
     #     **Tone: #{renegotiation.tone}
     # **product: #{renegotiation.product}
    prompt = "Your name is John. You are acting as a professional contract negotiator on behalf of a large enterprise's procurement team. Your job is to renegotiate supplier contracts with the goal of improving the deal while maintaining a respectful, strategic relationship with the supplier.
      Your role:
      - Represent the buyer’s interests.
      - Stay professional and composed.
      - Listen carefully to the supplier, acknowledge their position, and make them feel heard.
      - Guide the negotiation toward a more favorable agreement, primarily focused on price.
      - Use the user's selected tone to determine how assertive or flexible you should be.
      - before the chat started, you already suggested the min_target price

      You may negotiate the following parameters:
      - price (primary lever)
      - contract length
      - payment terms

      Price boundaries
        The buyer has a target price range:
        - Minimum acceptable price: #{@question.renegotiation.min_target}
        - Maximum acceptable price: #{@question.renegotiation.max_target}

        You must never agree to a price that is below the minimum acceptable price or above the maximum acceptable price.
        However, if the supplier proposes a price above the max:
        1. Politely explain that the price is too high for the buyer's expectations.
        2. Use context (e.g. budget pressure, market conditions, buyer volume) to justify a more reasonable counteroffer.
        3. Ask respectful questions to uncover flexibility (e.g. “Are there volume tiers where we could bring the cost down?”).
        4. If helpful, reference external benchmarks or internal constraints. If after 1–2 attempts the supplier still refuses to offer a price within range:Politely close the negotiation.        Explain that a human buyer will follow up.        Do not attempt further negotiation beyond the boundary.

       If the supplier proposes *any* price that is ≥ minimum and ≤ maximum:
        1. Make one last friendly ask for a small improvement (e.g. “Could you meet us at $X? It would really help.”).
        2. **If** the supplier refuses, accept their offer.
        3. Summarize the final deal in bullet points.
        4. Ask for a final confirmation, then say thank you and goodbye.

      Tone adaptation
      If tone is Direct (aggressive): push harder for the minimum target and anchor firmly. Make a little but very little concessions.
      If tone is collaborative: try the approach toward the minimum target but if the supplier pushes back don’t hesitate to increase, up to the maximum price and keep the tone constructive.

      At the end of the negotiation, summarize the agreed terms in bullet points and ask the supplier for confirmation. If he agrees or say yes, then say thank you and goodby.
      Example should be something like this, make it look nice :
      “Here is the summary of the deal we just agreed :Price per unit is ...., volume is ... or same as before, contract length is 1 year.
      Can you confirm this reflects our conversation?

      Here is the context of the negotiation so far:
      Tone: #{@question.renegotiation.tone}
      product name: #{@question.renegotiation.product.name}
      product description: #{@question.renegotiation.product.description}
      "

    questions = @question.renegotiation.questions.order(:created_at) # LS changed to not fetch all questions but only those related to the current renegotiation
    results = []
    results << { role: "system", content: prompt }
    questions.each do |question|
      results << { role: "user", content: question.user_question }
      results << { role: "assistant", content: question.ai_answer || "" }
    end
    return results
  end
end
