class AddProcurementToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :procurement_id, :bigint, null: false
    add_foreign_key :products, :users, column: :procurement_id
    add_index :products, :procurement_id  end
end
