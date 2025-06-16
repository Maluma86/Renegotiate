# Test status system with expiring contracts
puts "=== Testing Status with Expiring Contracts ==="

user1 = User.where(role: "procurement").first
user2 = User.where(role: "procurement").second

# Find or create a product that expires soon
expiring_product = Product.where(contract_end_date: (Date.current + 1.month)..(Date.current + 5.months)).first

if expiring_product.nil?
  # Update a product to expire soon for testing
  expiring_product = Product.first
  expiring_product.update!(contract_end_date: 3.months.from_now)
  puts "✅ Updated product '#{expiring_product.name}' to expire in 3 months"
end

puts "\nTest Product: #{expiring_product.name}"
puts "Contract expires: #{expiring_product.contract_end_date}"
puts "Expiring soon? #{expiring_product.contract_expiring_soon?}"

puts "\n=== Test 1: Available Status ===
Both users should see 'Available' since contract expires soon and no ongoing renegotiations"

# Clean any existing renegotiations
expiring_product.renegotiations.where(status: "Ongoing").destroy_all

puts "\nUser 1:"
puts "  Display Status: '#{expiring_product.display_status_for_user(user1)}'"
puts "  CSS Class: '#{expiring_product.display_status_css_class(user1)}'"

puts "\nUser 2:"
puts "  Display Status: '#{expiring_product.display_status_for_user(user2)}'"
puts "  CSS Class: '#{expiring_product.display_status_css_class(user2)}'"

puts "\n=== Test 2: Ongoing Status ===
User 1 creates renegotiation, should see 'Ongoing', User 2 should see 'Available'"

# Create ongoing renegotiation for User 1
renegotiation = Renegotiation.create!(
  product: expiring_product,
  buyer: user1,
  supplier: expiring_product.supplier,
  status: "Ongoing",
  min_target: 100,
  max_target: 200,
  tone: "collaborative"
)

puts "✅ Created ongoing renegotiation ID: #{renegotiation.id} for #{user1.company_name}"

puts "\nUser 1 (has ongoing):"
puts "  Display Status: '#{expiring_product.display_status_for_user(user1)}'"
puts "  CSS Class: '#{expiring_product.display_status_css_class(user1)}'"

puts "\nUser 2 (different company):"
puts "  Display Status: '#{expiring_product.display_status_for_user(user2)}'"
puts "  CSS Class: '#{expiring_product.display_status_css_class(user2)}'"

puts "\n=== Test 3: Human_Required Status ===
Change User 1's renegotiation to need human intervention"

renegotiation.update!(status: "Human_Required")

puts "\nUser 1 (needs human help):"
puts "  Display Status: '#{expiring_product.display_status_for_user(user1)}'"
puts "  CSS Class: '#{expiring_product.display_status_css_class(user1)}'"

puts "\nUser 2 (still different company):"
puts "  Display Status: '#{expiring_product.display_status_for_user(user2)}'"
puts "  CSS Class: '#{expiring_product.display_status_css_class(user2)}'"

puts "\n=== Test 4: Pending_Review Status ===
Test product that doesn't expire soon"

future_product = Product.where('contract_end_date > ?', 7.months.from_now).first
if future_product
  puts "\nFuture Product: #{future_product.name}"
  puts "Contract expires: #{future_product.contract_end_date}"
  puts "Expiring soon? #{future_product.contract_expiring_soon?}"
  
  puts "\nUser 1:"
  puts "  Display Status: '#{future_product.display_status_for_user(user1)}'"
  puts "  CSS Class: '#{future_product.display_status_css_class(user1)}'"
  
  puts "\nUser 2:"
  puts "  Display Status: '#{future_product.display_status_for_user(user2)}'"
  puts "  CSS Class: '#{future_product.display_status_css_class(user2)}'"
end

# Cleanup
renegotiation.destroy
puts "\n✅ Test renegotiation cleaned up"

puts "\n=== CSS Class to Status Mapping ===
The new system ensures CSS class matches display text:"
puts "  'available' → 'Available' (Green: ready to start)"
puts "  'ongoing' → 'Ongoing' (Blue: can continue)"
puts "  'human_required' → 'Human_Required' (Red: needs intervention)"
puts "  'pending_review' → 'Pending_Review' (Blue: waiting for 6-month window)"
puts "  'blocked' → 'Blocked' (Red: other company negotiating)"

puts "\n✅ Expiring contract status testing completed"