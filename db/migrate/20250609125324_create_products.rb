class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :category
      t.text :description
      t.float :current_price
      t.float :last_month_volume
      t.string :status
      t.date :contract_end_date

      t.timestamps
    end
  end
end
