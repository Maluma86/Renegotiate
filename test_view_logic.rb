# Test view logic for different scenarios
puts "=== Testing View Logic Scenarios ==="

# Setup users and products
user1 = User.where(role: "procurement").first
user2 = User.where(role: "procurement").second
products = Product.limit(3)

puts "User 1: #{user1.email} (#{user1.company_name})"
puts "User 2: #{user2.email} (#{user2.company_name})"

products.each_with_index do |product, index|
  puts "\n--- Product #{index + 1}: #{product.name} ---"
  puts "Contract expires: #{product.contract_end_date}"
  puts "Expiring soon? #{product.contract_expiring_soon?}"
  
  # Test for User 1
  puts "\nUser 1 view logic:"
  if product.renegotiation_allowed?(user1)
    puts "  → Show: 'Renegotiate' button (available)"
  elsif product.has_ongoing_renegotiation?(user1)
    ongoing = product.renegotiations
                    .joins(:buyer)
                    .find_by(users: { company_name: user1.company_name }, 
                            status: "ongoing")
    if ongoing
      puts "  → Show: 'Continue Renegotiation' button → ID #{ongoing.id}"
    else
      puts "  → ERROR: has_ongoing but can't find renegotiation"
    end
  elsif product.contract_expiring_soon?
    puts "  → Show: 'Renegotiation in progress' (blocked by other company)"
  else
    puts "  → Show: 'Review on #{product.next_review_date&.strftime("%d.%m.%Y")}'"
  end
  
  # Test for User 2  
  puts "\nUser 2 view logic:"
  if product.renegotiation_allowed?(user2)
    puts "  → Show: 'Renegotiate' button (available)"
  elsif product.has_ongoing_renegotiation?(user2)
    ongoing = product.renegotiations
                    .joins(:buyer)
                    .find_by(users: { company_name: user2.company_name }, 
                            status: "ongoing")
    if ongoing
      puts "  → Show: 'Continue Renegotiation' button → ID #{ongoing.id}"
    else
      puts "  → ERROR: has_ongoing but can't find renegotiation"
    end
  elsif product.contract_expiring_soon?
    puts "  → Show: 'Renegotiation in progress' (blocked by other company)"
  else
    puts "  → Show: 'Review on #{product.next_review_date&.strftime("%d.%m.%Y")}'"
  end
end

puts "\n=== Creating test renegotiation to verify Continue button ==="
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
  puts "Created test renegotiation ID: #{renegotiation.id}"
  
  puts "\nAfter creating renegotiation:"
  puts "User 1 view logic:"
  if test_product.renegotiation_allowed?(user1)
    puts "  → Show: 'Renegotiate' button (available)"
  elsif test_product.has_ongoing_renegotiation?(user1)
    ongoing = test_product.renegotiations
                         .joins(:buyer)
                         .find_by(users: { company_name: user1.company_name }, 
                                 status: "ongoing")
    puts "  → Show: 'Continue Renegotiation' button → ID #{ongoing.id}"
  elsif test_product.contract_expiring_soon?
    puts "  → Show: 'Renegotiation in progress'"
  else
    puts "  → Show: 'Review on #{test_product.next_review_date&.strftime("%d.%m.%Y")}'"
  end
  
  puts "\nUser 2 view logic (different company):"
  if test_product.renegotiation_allowed?(user2)
    puts "  → Show: 'Renegotiate' button (available)"
  elsif test_product.has_ongoing_renegotiation?(user2)
    ongoing = test_product.renegotiations
                         .joins(:buyer)
                         .find_by(users: { company_name: user2.company_name }, 
                                 status: "ongoing")
    puts "  → Show: 'Continue Renegotiation' button → ID #{ongoing.id}"
  elsif test_product.contract_expiring_soon?
    puts "  → Show: 'Renegotiation in progress' (blocked by User 1's company)"
  else
    puts "  → Show: 'Review on #{test_product.next_review_date&.strftime("%d.%m.%Y")}'"
  end
  
  # Cleanup
  renegotiation.destroy
  puts "\n✅ Test renegotiation cleaned up"
end

puts "\n✅ View logic testing completed"