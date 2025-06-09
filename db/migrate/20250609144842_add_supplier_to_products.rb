class AddSupplierToProducts < ActiveRecord::Migration[7.1]
  def change
    add_reference :products, :supplier, null: false, foreign_key: { to_table: :users }
  end
end
