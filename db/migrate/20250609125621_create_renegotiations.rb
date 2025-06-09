class CreateRenegotiations < ActiveRecord::Migration[7.1]
  def change
    create_table :renegotiations do |t|
      t.string :status
      t.text :thread
      t.string :tone
      t.float :min_target
      t.float :max_target
      t.float :new_price

      t.timestamps
    end
  end
end
