# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'faker'

# Clear existing data in development only
if Rails.env.development?
  puts "🧹 Clearing existing data..."
  Renegotiation.destroy_all
  Product.destroy_all
  User.destroy_all
  puts "✅ Data cleared"
end

# Create Procurement Users (Buyers)
puts "👥 Creating procurement users..."
procurement_users = []
10.times do
  procurement_users << User.create!(
    email: Faker::Internet.unique.email,
    password: "password123",
    role: "procurement",
    company_name: Faker::Company.name,
    contact: Faker::Name.name,
    contact_email: Faker::Internet.email
  )
end
puts "✅ Created #{procurement_users.count} procurement users"

# Create Supplier Users
puts "🏭 Creating supplier users..."
supplier_users = []
15.times do
  supplier_users << User.create!(
    email: Faker::Internet.unique.email,
    password: "password123",
    role: "supplier",
    company_name: Faker::Company.name,
    contact: Faker::Name.name,
    contact_email: Faker::Internet.email
  )
end
puts "✅ Created #{supplier_users.count} supplier users"

# Product categories for realistic data
categories = [
  "Office Supplies", "Technology", "Manufacturing Equipment",
  "Raw Materials", "Packaging", "Logistics", "Software Licenses",
  "Consulting Services", "Marketing Materials", "Industrial Tools"
]

# Create Products
puts "📦 Creating products..."
products = []
80.times do
  unit_price = Faker::Commerce.price(range: 50.0..5000.0)

  # Generate realistic monthly spending volume
  # Low-priced items: higher volume spending
  # High-priced items: lower volume spending
  if unit_price < 200
    volume_spending = Faker::Number.between(from: 1000, to: 25_000)  # $1K-$25K
  elsif unit_price < 1000
    volume_spending = Faker::Number.between(from: 2000, to: 40_000)  # $2K-$40K
  else
    volume_spending = Faker::Number.between(from: 5000, to: 100_000) # $5K-$100K
  end

  products << Product.create!(
    name: Faker::Commerce.product_name,
    category: categories.sample,
    description: Faker::Quote.famous_last_words,
    current_price: unit_price,
    last_month_volume: volume_spending,
    status: ["Ongoing", "Done", "Human required", "Pending"].sample,
    contract_end_date: Faker::Date.between(from: Date.today, to: 2.years.from_now),
    supplier: supplier_users.sample
  )
end
puts "✅ Created #{products.count} products"

# Create Renegotiations
puts "🤝 Creating renegotiations..."
renegotiations = []
30.times do
  product = products.sample
  buyer = procurement_users.sample

  # Generate realistic price targets
  current_price = product.current_price
  min_target = current_price * 0.7  # 30% discount max
  max_target = current_price * 0.9  # 10% discount min

  renegotiations << Renegotiation.create!(
    status: ["Initiated", "In Progress", "Completed", "Cancelled"].sample,
    thread: Faker::Quote.matz,
    tone: ["collaborative", "neutral", "aggressive"].sample,
    min_target: min_target,
    max_target: max_target,
    new_price: rand < 0.7 ? Faker::Commerce.price(range: min_target..max_target) : nil,
    product: product,
    buyer: buyer,
    supplier: product.supplier
  )
end
puts "✅ Created #{renegotiations.count} renegotiations"

# Create some demo users with known credentials
puts "🎭 Creating demo users..."
demo_procurement = User.create!(
  email: "buyer@demo.com",
  password: "demo123",
  role: "procurement",
  company_name: "Demo Manufacturing Corp",
  contact: "Jane Buyer",
  contact_email: "jane@demo.com"
)

demo_supplier = User.create!(
  email: "supplier@demo.com",
  password: "demo123",
  role: "supplier",
  company_name: "Demo Supplies Inc",
  contact: "John Supplier",
  contact_email: "john@supplier.com"
)

# Create demo products
demo_products = []
demo_prices = [100, 250, 500, 1000, 1500]
demo_volumes = [5000, 8000, 15_000, 25_000, 30_000] # Realistic spending volumes

5.times do |i|
  demo_products << Product.create!(
    name: "Demo Product #{i + 1}",
    category: categories.sample,
    description: "This is a demo product for testing the renegotiation platform",
    current_price: demo_prices[i],
    last_month_volume: demo_volumes[i], # Total spent last month
    status: "active",
    contract_end_date: 6.months.from_now,
    supplier: demo_supplier
  )
end

# Create demo renegotiation
Renegotiation.create!(
  status: "in_progress",
  thread: "Hi! We'd love to discuss better terms for our contract renewal as loyal customers.",
  tone: "collaborative",
  min_target: 800,
  max_target: 900,
  new_price: nil,
  product: demo_products.first,
  buyer: demo_procurement,
  supplier: demo_supplier
)

puts "✅ Created demo users and sample data"

puts "
🎉 Seed data creation complete!

📊 Summary:
- #{User.where(role: 'procurement').count} Procurement Users
- #{User.where(role: 'supplier').count} Supplier Users
- #{Product.count} Products
- #{Renegotiation.count} Renegotiations

🧪 Demo Accounts:
- Buyer: buyer@demo.com / demo123
- Supplier: supplier@demo.com / demo123

🚀 Run 'rails server' and start testing!
"
