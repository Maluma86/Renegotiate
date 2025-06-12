class AddAjaxDiscountColumnsToRenegotiations < ActiveRecord::Migration[7.0]
  def change
    add_column :renegotiations, :current_target_discount_percentage, :float
    add_column :renegotiations, :current_min_discount_percentage, :float
    add_column :renegotiations, :discount_targets_locked, :boolean, default: false, null: false
    add_column :renegotiations, :active_discount_target_version_id, :integer

    # Add index for the foreign key
    add_index :renegotiations, :active_discount_target_version_id
    
    # Add foreign key constraint to discount_target_histories table
    # Note: This references the discount_target_histories table created in the previous migration
    add_foreign_key :renegotiations, :discount_target_histories, column: :active_discount_target_version_id, on_delete: :nullify
  end
end
