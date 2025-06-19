# frozen_string_literal: true
# ---------------------------------------------------------------------
# Run with: bin/rails db:seed
# ---------------------------------------------------------------------
require "faker"

# ──────────────────────────────────────────────────────────────
# 0️⃣  Clean dev DB
# ──────────────────────────────────────────────────────────────
if Rails.env.development?
  puts "🧹 Clearing existing data..."
  [Question, DiscountTargetHistory, Renegotiation, Product, User].each(&:destroy_all)
  puts "✅ Data cleared"
end

# ──────────────────────────────────────────────────────────────
# 1️⃣  Core demo users
# ──────────────────────────────────────────────────────────────
puts "🎭 Creating demo users..."
walmart_buyer = User.find_or_create_by!(email: "buyer@walmart.com") do |u|
  u.password      = "demo123"
  u.role          = "procurement"
  u.company_name  = "Walmart"
  u.contact       = Faker::Name.name
  u.contact_email = u.email
end

carrefour_buyer = User.find_or_create_by!(email: "buyer@carrefour.com") do |u|
  u.password      = "demo123"
  u.role          = "procurement"
  u.company_name  = "Carrefour"
  u.contact       = Faker::Name.name
  u.contact_email = u.email
end

demo_supplier = User.find_or_create_by!(email: "supplier@demo.com") do |u|
  u.password      = "demo123"
  u.role          = "supplier"
  u.company_name  = "Demo Supplies Inc"
  u.contact       = Faker::Name.name
  u.contact_email = u.email
end
puts "✅ Demo users ready"

# ──────────────────────────────────────────────────────────────
# 2️⃣  Extra suppliers (20 random + demo)
# ──────────────────────────────────────────────────────────────
puts "🏭 Creating suppliers..."
suppliers = Array.new(20) do
  User.create!(
    email:         Faker::Internet.unique.email,
    password:      "password123",
    role:          "supplier",
    company_name:  Faker::Company.name,
    contact:       Faker::Name.name,
    contact_email: Faker::Internet.email
  )
end
suppliers << demo_supplier
puts "✅ #{suppliers.size} suppliers created"

# ──────────────────────────────────────────────────────────────
# Helpers for capped date buckets
# ──────────────────────────────────────────────────────────────
def build_future_dates(total, days_ahead:, max_per_day:)
  counts = Hash.new(0)
  dates  = []
  while dates.size < total
    offset = rand(days_ahead)          # 0…days_ahead-1
    next if counts[offset] >= max_per_day
    counts[offset] += 1
    dates << (Date.today + offset)
  end
  dates.shuffle
end

def build_past_dates(total, range_start, range_end, max_per_day:)
  offsets = (range_start..range_end).to_a
  counts  = Hash.new(0)
  dates   = []
  while dates.size < total
    offset = offsets.sample
    next if counts[offset] >= max_per_day
    counts[offset] += 1
    dates << (Date.today - offset)
  end
  dates.shuffle
end

# ──────────────────────────────────────────────────────────────
# 3️⃣ creating real products for walmart
# ──────────────────────────────────────────────────────────────
puts "📦 Creating 15 real-world Walmart products..."

products = []
products << Product.create!(
  name:              "Organic Bananas",
  category:          "Raw Materials",
  description:       "Fresh organic bananas sourced from Central America",
  current_price:     0.20,
  last_month_volume: 100_000,
  contract_end_date: Date.today + 7,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "LED 55\" Television",
  category:          "Technology",
  description:       "55-inch 4K Ultra HD LED TV",
  current_price:     400.00,
  last_month_volume: 200,
  contract_end_date: Date.today + 14,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Office Stapler",
  category:          "Office Supplies",
  description:       "Heavy-duty desk stapler",
  current_price:     5.99,
  last_month_volume: 5_000,
  contract_end_date: Date.today + 30,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Blue Ballpoint Pens (Pack of 12)",
  category:          "Office Supplies",
  description:       "Smooth-writing blue ink pens",
  current_price:     3.50,
  last_month_volume: 10_000,
  contract_end_date: Date.today + 5,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Industrial Printer",
  category:          "Manufacturing Equipment",
  description:       "High-speed commercial printer",
  current_price:     1_500.00,
  last_month_volume: 15,
  contract_end_date: Date.today + 20,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Plastic Shipping Pallets",
  category:          "Logistics",
  description:       "Heavy-duty reusable pallets",
  current_price:     50.00,
  last_month_volume: 1_000,
  contract_end_date: Date.today + 60,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Raw Cotton Bales",
  category:          "Raw Materials",
  description:       "Grade A cotton bales",
  current_price:     600.00,
  last_month_volume: 200,
  contract_end_date: Date.today + 25,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Wireless Mouse",
  category:          "Technology",
  description:       "Ergonomic USB wireless mouse",
  current_price:     25.00,
  last_month_volume: 3_000,
  contract_end_date: Date.today + 40,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Paper Towels (Case of 24)",
  category:          "Office Supplies",
  description:       "Multipurpose absorbent rolls",
  current_price:     15.00,
  last_month_volume: 8_000,
  contract_end_date: Date.today + 12,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Stainless Steel Water Bottles (Pack of 24)",
  category:          "Logistics",
  description:       "Insulated reusable bottles",
  current_price:     120.00,
  last_month_volume: 500,
  contract_end_date: Date.today + 50,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Cotton T-Shirts (Pack of 100)",
  category:          "Raw Materials",
  description:       "100% cotton crew-neck tees",
  current_price:     800.00,
  last_month_volume: 500,
  contract_end_date: Date.today + 28,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Laptop Computers",
  category:          "Technology",
  description:       "14\" business-class laptops",
  current_price:     800.00,
  last_month_volume: 150,
  contract_end_date: Date.today + 35,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Hand Sanitizer (Gallon)",
  category:          "Office Supplies",
  description:       "70% ethyl alcohol sanitizer",
  current_price:     20.00,
  last_month_volume: 4_000,
  contract_end_date: Date.today + 8,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Inkjet Printer Cartridges (Pack of 4)",
  category:          "Office Supplies",
  description:       "Universal refillable cartridges",
  current_price:     45.00,
  last_month_volume: 5_000,
  contract_end_date: Date.today + 22,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

products << Product.create!(
  name:              "Kitchen Blender",
  category:          "Technology",
  description:       "Countertop blender with 1.5L jar",
  current_price:     60.00,
  last_month_volume: 300,
  contract_end_date: Date.today + 55,
  supplier:          suppliers.sample,
  procurement:       walmart_buyer
)

puts "✅ Created #{products.count} products"

# ──────────────────────────────────────────────────────────────
# 4️⃣  Renegotiations – 70 completed (spread) + 33 current
# ──────────────────────────────────────────────────────────────
puts "🤝 Creating renegotiations..."

# Build 20 / 30 / 20 completed slots: days_0-29, 30-59, 60-89
completed_dates =
  build_past_dates(20, 0, 29,  max_per_day: 4) +
  build_past_dates(30, 30, 59, max_per_day: 4) +
  build_past_dates(20, 60, 89, max_per_day: 4)

def discount_targets(price)
  tgt_pct = rand(4.5..6.5).round(1)        # keeps mean under 7 %
  min_pct = rand(2.0..4.0).round(1)
  [
    (price * (1 - tgt_pct/100)).round(2),  # min_target
    (price * (1 - min_pct/100)).round(2),  # max_target
    tgt_pct, min_pct
  ]
end

renegs = []

# ⏸Picking 10 random walmart products to remain pending (no renegotiations)
pending_products = products.sample(10)

# The rest will get renegotiations attached
negotiable_products = products - pending_productss


# Completed renegotiations
completed_dates.each do |day|
  product = negotiable_products.sample
  min_t, max_t, tgt_pct, min_pct = discount_targets(product.current_price)

  renegs << Renegotiation.create!(
    status: %w[done done done locked].sample,
    thread: Faker::Quote.matz,
    tone:   %w[collaborative neutral aggressive].sample,
    min_target: min_t,
    max_target: max_t,
    new_price:  Faker::Commerce.price(range: min_t..max_t),
    product:    product,
    buyer:      walmart_buyer,
    supplier:   product.supplier,
    created_at: (day - 2.days).to_time.change(hour: 10),
    updated_at: day.to_time.change(hour: 12),
    current_target_discount_percentage: tgt_pct,
    current_min_discount_percentage:    min_pct,
    discount_targets_locked:            true
  )
end

# Current renegotiations
33.times do
  product = products.sample
  min_t, max_t, tgt_pct, min_pct = discount_targets(product.current_price)
  ts = Faker::Time.between(from: 90.days.ago, to: Time.current)

  renegs << Renegotiation.create!(
    status: %w[ongoing ongoing escalated].sample,
    thread: Faker::Quote.matz,
    tone:   %w[collaborative neutral aggressive].sample,
    min_target: min_t,
    max_target: max_t,
    product:    product,
    buyer:      walmart_buyer,
    supplier:   product.supplier,
    created_at: ts,
    updated_at: ts,
    current_target_discount_percentage: tgt_pct,
    current_min_discount_percentage:    min_pct,
    discount_targets_locked:            false
  )
end
puts "✅ #{Renegotiation.where(status: %w[done locked]).count} completed, #{Renegotiation.where(status: %w[ongoing escalated]).count} current"

# ──────────────────────────────────────────────────────────────
# 5️⃣  Discount-target histories – 2-5 per renegotiation
# ──────────────────────────────────────────────────────────────
puts "🗂️  Creating discount-target histories..."
DiscountTargetHistory.destroy_all

renegs.each do |neg|
  versions = rand(2..5)
  versions.times do |v|
    tgt = (neg.current_target_discount_percentage + rand(-0.4..0.4)).round(1)
    min = (neg.current_min_discount_percentage    + rand(-0.4..0.4)).clamp(0.0, tgt).round(1)
    ts  = Faker::Time.between(from: neg.created_at, to: neg.created_at + 5.days)

    rec = DiscountTargetHistory.create!(
      renegotiation:              neg,
      target_discount_percentage: tgt,
      min_discount_percentage:    min,
      set_by_user_id:             walmart_buyer.id,
      set_at:                     ts,
      version_number:             v + 1,
      is_active:                  v + 1 == versions,
      created_at:                 ts,
      updated_at:                 ts
    )

    neg.update!(
      current_target_discount_percentage: tgt,
      current_min_discount_percentage:    min,
      active_discount_target_version_id:  rec.id
    ) if rec.is_active
  end
end
puts "✅ #{DiscountTargetHistory.count} history rows"

# ──────────────────────────────────────────────────────────────
# 6️⃣  Questions – 1-3 for each current renegotiation
# ──────────────────────────────────────────────────────────────
puts "💬 Creating Q&A pairs..."
question_bank = [
  "Can you confirm volume commitment at the proposed price?",
  "What lead-time improvements can we expect?",
  "Would you accept a stepped discount if volumes rise by 15 %?"
]
answer_bank = [
  "Based on the last 6 months, that commitment is realistic.",
  "Lead-time would drop from 8 days to 5 days once the new contract is signed.",
  "Yes, we can formalise a stepped discount table in the contract appendix."
]
q_total = 0

Renegotiation.where(status: %w[ongoing escalated]).find_each do |neg|
  rand(1..3).times do
    ts = Faker::Time.between(from: neg.created_at, to: neg.updated_at)
    Question.create!(
      user_question: question_bank.sample,
      ai_answer:     answer_bank.sample,
      user:          walmart_buyer,
      renegotiation: neg,
      created_at:    ts,
      updated_at:    ts
    )
    q_total += 1
  end
end
puts "✅ Created #{q_total} Q&A pairs"

# ──────────────────────────────────────────────────────────────
# 7️⃣  Final summary
# ──────────────────────────────────────────────────────────────
puts "
🎉 Seed complete!

📊 Totals
   • Products:          #{Product.count}   (35 renew ≤30 days)
   • Renegotiations:    #{Renegotiation.count}
        ↳ Completed:    #{Renegotiation.where(status: %w[done locked]).count}
        ↳ Current:      #{Renegotiation.where(status: %w[ongoing escalated]).count}
   • Histories:         #{DiscountTargetHistory.count}
   • Questions:         #{Question.count}

🧪 Demo logins
   buyer@walmart.com / demo123
   supplier@demo.com / demo123
"
