class AddRenegotiationToQuestions < ActiveRecord::Migration[7.1]
  def change
    add_reference :questions, :renegotiation, null: false, foreign_key: true
  end
end
