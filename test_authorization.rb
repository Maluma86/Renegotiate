# Test authorization edge cases and robustness
puts "=== Testing Authorization Edge Cases ==="

# Setup users
user1 = User.where(role: "procurement").first
user2 = User.where(role: "procurement").second
puts "User 1: #{user1.email} (#{user1.company_name})"
puts "User 2: #{user2.email} (#{user2.company_name})"

# Setup products with different scenarios
product_soon = Product.first
product_later = Product.second
product_soon.update!(contract_end_date: 2.months.from_now)
product_later.update!(contract_end_date: 8.months.from_now)

puts "\nProduct Soon: #{product_soon.name} (expires: #{product_soon.contract_end_date})"
puts "Product Later: #{product_later.name} (expires: #{product_later.contract_end_date})"

# Clear existing renegotiations
Renegotiation.where(product: [product_soon, product_later], status: "ongoing").destroy_all

puts "\n=== Test 1: Contract timing authorization ==="
puts "Product expiring soon (2 months):"
puts "  contract_expiring_soon?: #{product_soon.contract_expiring_soon?}"
puts "  renegotiation_allowed?: #{product_soon.renegotiation_allowed?(user1)}"

puts "Product expiring later (8 months):"
puts "  contract_expiring_soon?: #{product_later.contract_expiring_soon?}"
puts "  renegotiation_allowed?: #{product_later.renegotiation_allowed?(user1)}"

puts "\n=== Test 2: Authorization with ongoing renegotiation ==="
# Create ongoing renegotiation for soon-expiring product
renegotiation = Renegotiation.create!(
  product: product_soon,
  buyer: user1,
  supplier: product_soon.supplier,
  status: "ongoing",
  min_target: 100,
  max_target: 200,
  tone: "collaborative"
)
puts "Created ongoing renegotiation ID: #{renegotiation.id}"

puts "After creating ongoing renegotiation:"
puts "  User 1 (same company): renegotiation_allowed? = #{product_soon.renegotiation_allowed?(user1)}"
puts "  User 2 (diff company): renegotiation_allowed? = #{product_soon.renegotiation_allowed?(user2)}"

puts "\n=== Test 3: Status transitions ==="
puts "Status for expiring product with ongoing:"
puts "  User 1: #{product_soon.renegotiation_status_for_user(user1)}"
puts "  User 2: #{product_soon.renegotiation_status_for_user(user2)}"

puts "Status for later product:"
puts "  User 1: #{product_later.renegotiation_status_for_user(user1)}"

puts "\n=== Test 4: Edge case - nil contract date ==="
product_no_date = Product.third
original_date = product_no_date.contract_end_date

# Test behavior with current date first
puts "Product with current contract_end_date (#{original_date}):"
puts "  contract_expiring_soon?: #{product_no_date.contract_expiring_soon?}"
puts "  renegotiation_allowed?: #{product_no_date.renegotiation_allowed?(user1)}"
puts "  next_review_date: #{product_no_date.next_review_date.inspect}"
puts "  status: #{product_no_date.renegotiation_status_for_user(user1)}"

# Note: Skipping nil test due to validation constraint
puts "\nNote: Skipping nil contract_end_date test due to Product validation requiring this field"

puts "\n=== Test 5: Completed renegotiation scenario ==="
# Change status to completed
renegotiation.update!(status: "done")
puts "After marking renegotiation as 'done':"
puts "  has_ongoing_renegotiation?: #{product_soon.has_ongoing_renegotiation?(user1)}"
puts "  renegotiation_allowed?: #{product_soon.renegotiation_allowed?(user1)}"
puts "  status: #{product_soon.renegotiation_status_for_user(user1)}"

puts "\n=== Test 6: Multiple status scenarios ==="
# Test different renegotiation statuses
test_statuses = ["ongoing", "done", "human_required"]
test_statuses.each do |status|
  renegotiation.update!(status: status)
  puts "Status '#{status}':"
  puts "  has_ongoing?: #{product_soon.has_ongoing_renegotiation?(user1)}"
  puts "  allowed?: #{product_soon.renegotiation_allowed?(user1)}"
end

puts "\n=== Test 7: Authorization consistency ==="
# Verify authorization logic is consistent
products_to_test = [product_soon, product_later]
products_to_test.each do |product|
  allowed = product.renegotiation_allowed?(user1)
  has_ongoing = product.has_ongoing_renegotiation?(user1)
  expiring_soon = product.contract_expiring_soon?
  
  puts "#{product.name}:"
  puts "  expiring_soon: #{expiring_soon}, has_ongoing: #{has_ongoing}, allowed: #{allowed}"
  
  # Logic check: allowed should be true only if expiring_soon AND NOT has_ongoing
  expected_allowed = expiring_soon && !has_ongoing
  if allowed == expected_allowed
    puts "  ✅ Authorization logic consistent"
  else
    puts "  ❌ Authorization logic inconsistent! Expected: #{expected_allowed}, Got: #{allowed}"
  end
end

# Cleanup
renegotiation.destroy
puts "\n✅ Authorization testing completed and cleaned up"