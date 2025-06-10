# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


# Clear existing data
User.destroy_all
Product.destroy_all

# Create sample user
User.create!(
  email: "user@user.com",
  password: "user123",
  role: "procurement",
  company_name: "Test",
  contact: "John Test",
  contact_email: "john@test.com"
)

User.create!(
  email: "sdsdsd@user.com",
  password: "user1235",
  role: "supplier",
  company_name: "Collgate",
  contact: "Max Max",
  contact_email: "Max@test.com"
)

# Create sample product
Product.create!(
  name: "Test Product",
  category: "test",
  description: "Sample item",
  current_price: 100.0,
  status: "active",
  contract_end_date: Date.today + 1.year,
  supplier_id: User.second.id
)

Product.create!(
  name: "Test 2",
  category: "Shampoo",
  description: "Sample item",
  current_price: 140.0,
  status: "active",
  contract_end_date: Date.today + 1.year,
  supplier_id: User.second.id
)

puts "Seeded 1 user and 1 product"
