class AddContactToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :contact, :string
  end
end
