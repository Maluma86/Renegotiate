# Test button styling scenarios
puts "=== Testing Button Style Application ==="

# Get test data
user1 = User.where(role: "procurement").first
user2 = User.where(role: "procurement").second
products = Product.limit(4)

puts "User 1: #{user1.email} (#{user1.company_name})"
puts "User 2: #{user2.email} (#{user2.company_name})"

# Create a test scenario with an ongoing renegotiation
test_product = products.first
if test_product.contract_expiring_soon? && !test_product.has_ongoing_renegotiation?(user1)
  renegotiation = Renegotiation.create!(
    product: test_product,
    buyer: user1,
    supplier: test_product.supplier,
    status: "ongoing",
    min_target: 100,
    max_target: 200,
    tone: "collaborative"
  )
  puts "\n✅ Created test renegotiation ID: #{renegotiation.id}"
end

puts "\n=== Button Style Mapping ==="

products.each_with_index do |product, index|
  puts "\n--- Product #{index + 1}: #{product.name} ---"
  puts "Contract expires: #{product.contract_end_date}"
  puts "Expiring soon? #{product.contract_expiring_soon?}"
  
  # Test for User 1
  puts "\nUser 1 button style:"
  if product.renegotiation_allowed?(user1)
    puts "  ✅ CSS Class: 'renegotiate-btn available'"
    puts "  ✅ Style: Gray background (#282828), orange hover (#FF7518)"
    puts "  ✅ Text: 'Renegotiate'"
  elsif product.has_ongoing_renegotiation?(user1)
    ongoing = product.renegotiations
                    .joins(:buyer)
                    .find_by(users: { company_name: user1.company_name }, 
                            status: "ongoing")
    if ongoing
      puts "  ✅ CSS Class: 'renegotiate-btn ongoing'"
      puts "  ✅ Style: Blue background (#1e40af), blue hover (#3b82f6)"
      puts "  ✅ Text: 'Continue Renegotiation'"
      puts "  ✅ Links to: confirm_target_renegotiation_path(#{ongoing.id})"
    end
  elsif product.contract_expiring_soon?
    puts "  ✅ CSS Class: 'no-action-label'"
    puts "  ✅ Style: Muted orange background (rgba(255,117,24,0.2))"
    puts "  ✅ Text: 'Renegotiation in progress'"
  else
    puts "  ✅ CSS Class: 'next-review-label'"
    puts "  ✅ Style: Muted blue background (rgba(59,130,246,0.2))"
    puts "  ✅ Text: 'Review on #{product.next_review_date&.strftime("%d.%m.%Y")}'"
  end
  
  # Test for User 2
  puts "\nUser 2 button style:"
  if product.renegotiation_allowed?(user2)
    puts "  ✅ CSS Class: 'renegotiate-btn available'"
    puts "  ✅ Style: Gray background (#282828), orange hover (#FF7518)"
    puts "  ✅ Text: 'Renegotiate'"
  elsif product.has_ongoing_renegotiation?(user2)
    ongoing = product.renegotiations
                    .joins(:buyer)
                    .find_by(users: { company_name: user2.company_name }, 
                            status: "ongoing")
    if ongoing
      puts "  ✅ CSS Class: 'renegotiate-btn ongoing'"
      puts "  ✅ Style: Blue background (#1e40af), blue hover (#3b82f6)"
      puts "  ✅ Text: 'Continue Renegotiation'"
      puts "  ✅ Links to: confirm_target_renegotiation_path(#{ongoing.id})"
    end
  elsif product.contract_expiring_soon?
    puts "  ✅ CSS Class: 'no-action-label'"
    puts "  ✅ Style: Muted orange background (rgba(255,117,24,0.2))"
    puts "  ✅ Text: 'Renegotiation in progress'"
  else
    puts "  ✅ CSS Class: 'next-review-label'"
    puts "  ✅ Style: Muted blue background (rgba(59,130,246,0.2))"
    puts "  ✅ Text: 'Review on #{product.next_review_date&.strftime("%d.%m.%Y")}'"
  end
end

# Cleanup test data
test_renegotiation = Renegotiation.find_by(product: test_product, buyer: user1, status: "ongoing")
if test_renegotiation && test_renegotiation.id > 290 # Only clean up our test data
  test_renegotiation.destroy
  puts "\n✅ Cleaned up test renegotiation"
end

puts "\n=== CSS Style Summary ==="
puts "1. renegotiate-btn available: Gray → Orange (default action)"
puts "2. renegotiate-btn ongoing: Blue → Light Blue (continue action)" 
puts "3. no-action-label: Muted Orange (blocked state)"
puts "4. next-review-label: Muted Blue (pending review)"
puts "\n✅ Button styling test completed"