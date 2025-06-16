# Test new business rule-based status system
puts "=== Testing New Business Rule-Based Status System ==="

user1 = User.where(role: "procurement").first
user2 = User.where(role: "procurement").second

puts "User 1: #{user1.email} (#{user1.company_name})"
puts "User 2: #{user2.email} (#{user2.company_name})"

products = Product.limit(4)

products.each_with_index do |product, index|
  puts "\n--- Product #{index + 1}: #{product.name} ---"
  puts "Contract expires: #{product.contract_end_date}"
  puts "Expiring soon? #{product.contract_expiring_soon?}"
  
  # Test User 1
  puts "\n👤 User 1 Status:"
  puts "  Display Status: '#{product.display_status_for_user(user1)}'"
  puts "  CSS Class: '#{product.display_status_css_class(user1)}'"
  puts "  Authorization: renegotiation_allowed? = #{product.renegotiation_allowed?(user1)}"
  puts "  Has Ongoing: has_ongoing_renegotiation? = #{product.has_ongoing_renegotiation?(user1)}"
  
  # Test User 2
  puts "\n👤 User 2 Status:"
  puts "  Display Status: '#{product.display_status_for_user(user2)}'"
  puts "  CSS Class: '#{product.display_status_css_class(user2)}'"
  puts "  Authorization: renegotiation_allowed? = #{product.renegotiation_allowed?(user2)}"
  puts "  Has Ongoing: has_ongoing_renegotiation? = #{product.has_ongoing_renegotiation?(user2)}"
  
  # Compare with old system
  puts "\n🔄 Old vs New Comparison:"
  puts "  Old product.status: '#{product.status}'"
  puts "  Old renegotiation_status: '#{product.renegotiation_status}'"
  puts "  New User 1 status: '#{product.display_status_for_user(user1)}'"
  puts "  New User 2 status: '#{product.display_status_for_user(user2)}'"
end

puts "\n=== Create Test Scenario with Ongoing Renegotiation ==="

# Create ongoing renegotiation for testing
test_product = products.first
if test_product.contract_expiring_soon? && !test_product.has_ongoing_renegotiation?(user1)
  test_renegotiation = Renegotiation.create!(
    product: test_product,
    buyer: user1,
    supplier: test_product.supplier,
    status: "Ongoing",
    min_target: 100,
    max_target: 200,
    tone: "collaborative"
  )
  
  puts "✅ Created test renegotiation ID: #{test_renegotiation.id}"
  
  puts "\nAfter creating ongoing renegotiation:"
  puts "User 1 (same company):"
  puts "  Display Status: '#{test_product.display_status_for_user(user1)}'"
  puts "  CSS Class: '#{test_product.display_status_css_class(user1)}'"
  
  puts "User 2 (different company):"
  puts "  Display Status: '#{test_product.display_status_for_user(user2)}'"
  puts "  CSS Class: '#{test_product.display_status_css_class(user2)}'"
  
  # Test Human_Required status
  test_renegotiation.update!(status: "Human_Required")
  puts "\nAfter setting renegotiation to Human_Required:"
  puts "User 1:"
  puts "  Display Status: '#{test_product.display_status_for_user(user1)}'"
  puts "  CSS Class: '#{test_product.display_status_css_class(user1)}'"
  
  # Cleanup
  test_renegotiation.destroy
  puts "\n✅ Test renegotiation cleaned up"
end

puts "\n=== Status System Comparison Summary ==="
puts "📊 Old System Issues:"
puts "  • CSS class from product.status, text from renegotiation_status (mismatch)"
puts "  • Not user-specific (same status for all users)"
puts "  • Not aligned with business authorization logic"

puts "\n✅ New System Benefits:"
puts "  • CSS class and text from same source (no mismatch)"
puts "  • User-specific status (reflects what each user can do)"
puts "  • Aligned with business authorization logic"
puts "  • Clear visual indication of available actions"

puts "\n✅ New status system testing completed"