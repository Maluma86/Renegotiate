class Question < ApplicationRecord
  belongs_to :user
  belongs_to :renegotiation #LS added this to fix the error
  validates :user_question, presence: true
  after_create :fetch_ai_answer

  private

  def fetch_ai_answer
    ChatbotJob.perform_later(self)
  end
end
