class AddUniqueIndexToRenegotiations < ActiveRecord::Migration[7.1]
  def change
    # Add unique constraint to prevent duplicate ongoing renegotiations
    # This ensures only one ongoing renegotiation per product per company
    add_index :renegotiations, 
              [:product_id, :buyer_id, :status], 
              unique: true,
              where: "status = 'ongoing'",
              name: 'unique_ongoing_renegotiation_per_product_buyer'
  end
end
