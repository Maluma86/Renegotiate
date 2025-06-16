# class QuestionsController < ApplicationController
#   def index
#     # @questions = current_user.questions
#     # @question = Question.new # for form
#   end
# end

class QuestionsController < ApplicationController
  # [...]
  def create
    @questions = current_user.questions # needed in case of validation error
    @question = Question.new(question_params)
    @question.user = current_user
    if @question.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(:questions, partial: "renegotiations/question",
            locals: { question: @question })
        end
        format.html { redirect_to questions_path }
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
