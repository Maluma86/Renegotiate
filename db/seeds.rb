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

# Create 4 Specific Procurement Users with known credentials
puts "👥 Creating specific procurement users..."
procurement_users = []

# Create 4 users with specific product counts
user_configs = [
  { email: "user1@demo.com", products: 10 },
  { email: "user2@demo.com", products: 25 },
  { email: "user3@demo.com", products: 25 },
  { email: "user4@demo.com", products: 20 }
]

user_configs.each do |config|
  procurement_users << User.create!(
    email: config[:email],
    password: "demo123",
    role: "procurement",
    company_name: Faker::Company.name,
    contact: Faker::Name.name,
    contact_email: config[:email]
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
  "Fun tools", "Marketing Materials", "Industrial Tools"
]

# Create Products assigned to specific users
puts "📦 Creating products..."
products = []

user_configs.each_with_index do |config, index|
  user = procurement_users[index]
  config[:products].times do
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
      description: "#{Faker::Company.catch_phrase}. #{Faker::Company.bs.capitalize}.",
      current_price: unit_price,
      last_month_volume: volume_spending,
      status: ["Ongoing", "Done", "Human_Required", "Pending"].sample,
      contract_end_date: Faker::Date.between(from: Date.today, to: 2.years.from_now),
      supplier: supplier_users.sample,
      procurement: user
    )
  end
end
puts "✅ Created #{products.count} products distributed to specific users"

# Create Renegotiations
puts "🤝 Creating renegotiations..."
renegotiations = []
30.times do
  product = products.sample
  buyer = product.procurement  # Use the procurement user assigned to the product

  # Generate realistic price targets
  current_price = product.current_price
  min_target = current_price * 0.7  # 30% discount max
  max_target = current_price * 0.9  # 10% discount min

  renegotiations << Renegotiation.create!(
    status: ["Ongoing", "Done", "Human_Required"].sample,
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
demo_procurement1 = User.create!(
  email: "buyer@Walmart.com",
  password: "demo123",
  role: "procurement",
  company_name: "Walmart",
  contact: "Jane Buyer",
  contact_email: "buyer@Walmart.com"
)
demo_procurement2 = User.create!(
  email: "buyer@Carrefour.com",
  password: "demo123",
  role: "procurement",
  company_name: "Walmart",
  contact: "jean Dupont",
  contact_email: "buyer@Carrefour.com"
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
    status: "Pending",
    contract_end_date: 6.months.from_now,
    supplier: demo_supplier,
    procurement: demo_procurement1
  )
end

# Create a demo renegotiation linked to the first product of walmart that is ongoing
Renegotiation.create!(
  status: "Ongoing",
  thread: "Hi! We'd love to discuss better terms for our contract renewal as loyal customers.",
  tone: "collaborative",
  min_target: 800,
  max_target: 900,
  new_price: nil,
  product: demo_products.first,
  buyer: demo_procurement1,
  supplier: demo_supplier
)

Renegotiation.create!(
  status: "Human_Required",
  thread: "Hi! We'd love to discuss better terms for our contract renewal as loyal customers.",
  tone: "collaborative",
  min_target: 800,
  max_target: 900,
  new_price: nil,
  product: demo_products.second,
  buyer: demo_procurement1,
  supplier: demo_supplier
)

Renegotiation.create!(
  status: "Done",
  thread: "Hi! We'd love to discuss better terms for our contract renewal as loyal customers.",
  tone: "collaborative",
  min_target: 800,
  max_target: 900,
  new_price: nil,
  product: demo_products.third,
  buyer: demo_procurement1,
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
- Buyer1: buyer@Walmart.com / demo123 -> has already 5 products attached
- Buyer2: buyer@Carrefour.com / demo123 -> no products attached. Need to import. Should not see the products from Carrefour.
- Supplier: supplier@demo.com / demo123

👥 Test Users (password: demo123):
- user1@demo.com -> 10 products
- user2@demo.com -> 25 products
- user3@demo.com -> 25 products  
- user4@demo.com -> 20 products

🚀 Run 'rails server' and start testing!
"
