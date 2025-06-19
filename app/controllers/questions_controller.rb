# class QuestionsController < ApplicationController
#   def index
#     # @questions = current_user.questions
#     # @question = Question.new # for form
#   end
# end

class QuestionsController < ApplicationController
  before_action :set_renegotiation, only: [:create] # LS added
  def create
  @question = @renegotiation.questions.build(question_params)
  @question.user = current_user

  if @question.save
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: [
          # 1) append the new message bubble
          turbo_stream.append(
            "questions",
            partial: "renegotiations/question",
            locals: { question: @question }
          ),
          # 2) reset the form by replacing it with a fresh empty one
          turbo_stream.replace(
            "new_question",
            partial: "renegotiations/form",
            locals: { question: Question.new, renegotiation: @renegotiation }
          )
        ]
      }
      format.html { redirect_to renegotiation_path(@renegotiation) }
    end
  else
      # On failure, reload whatever Renegotiations#show needs…
      @product   = @renegotiation.product
      @supplier  = @renegotiation.supplier
      @questions = @renegotiation.questions.order(:created_at)
      # and re-render the show view with an HTTP 422
      render "renegotiations/show", status: :unprocessable_entity
    end
  end

  private

   def set_renegotiation
    # assumes your routes are nested: /renegotiations/:renegotiation_id/questions
    @renegotiation = Renegotiation.find(params[:renegotiation_id])
  end

  def question_params
    params.require(:question).permit(:user_question)
  end
end
