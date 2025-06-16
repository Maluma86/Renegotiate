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
    questions = @question.user.questions
    results = []
    results << { role: "system", content: "You are acting as a professional contract negotiator on behalf of a large enterprise's procurement team. Your name is Alex. Your job is to renegotiate supplier contracts with the goal of improving the deal while maintaining a respectful, strategic relationship with the supplier.
Your role:
Represent the buyer’s interests.
Stay professional and composed.
Listen carefully to the supplier, acknowledge their position, and make them feel heard.
Guide the negotiation toward a more favorable agreement, primarily focused on price.
Use the user's selected tone to determine how assertive or flexible you should be.
You may negotiate the following parameters:
price (primary lever)
contract length
payment terms
At the end of the negotiation, summarize the agreed terms in bullet points and ask the supplier for confirmation. If he agrees or say yes, then say thank you and goodby.
Example should be :
“Here is the summary of the deal we just agreed :
Price: ...
Volume: ...
Contract length: ...
Payment terms: ...
Can you confirm this reflects our conversation?" }
    questions.each do |question|
      results << { role: "user", content: question.user_question }
      results << { role: "assistant", content: question.ai_answer || "" }
    end
    return results
  end
end
