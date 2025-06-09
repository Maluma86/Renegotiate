class AddProductToRenegotiations < ActiveRecord::Migration[7.1]
  def change
    add_reference :renegotiations, :product, null: false, foreign_key: true
    add_reference :renegotiations, :buyer, null: false, foreign_key: { to_table: :users }
    add_reference :renegotiations, :supplier, null: false, foreign_key: { to_table: :users }
  end
end
