class CreateAjaxDiscountTargetHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :discount_target_histories do |t|
      t.references :renegotiation, null: false, foreign_key: true
      t.float :target_discount_percentage, null: false
      t.float :min_discount_percentage, null: false
      t.integer :set_by_user_id, null: false
      t.datetime :set_at, null: false
      t.integer :version_number, null: false, default: 1
      t.boolean :is_active, null: false, default: true
      t.text :notes

      t.timestamps
    end

    # Add indexes for performance
    add_index :discount_target_histories, [:renegotiation_id, :version_number], unique: true, name: 'index_discount_histories_on_renegotiation_and_version'
    add_index :discount_target_histories, [:renegotiation_id, :is_active], name: 'index_discount_histories_on_renegotiation_and_active'
    add_index :discount_target_histories, :set_by_user_id
    
    # Add foreign key for set_by_user_id
    add_foreign_key :discount_target_histories, :users, column: :set_by_user_id
  end
end
