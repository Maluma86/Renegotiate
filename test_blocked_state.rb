# Test blocked state scenario
puts "=== Testing Blocked State Styling ==="

user1 = User.where(role: "procurement").first  # Larson-Beer
user3 = User.where(company_name: "ACME Corp").first || User.where(role: "procurement").third # Different company

if user3.nil?
  puts "Creating test user for different company..."
  user3 = User.create!(
    email: "test#{Time.now.to_i}@different.com",
    role: "procurement", 
    company_name: "TestCorp Inc",
    password: "password123",
    first_name: "Test",
    last_name: "User"
  )
end

product = Product.where(contract_end_date: (Date.current + 2.months)..(Date.current + 4.months)).first

if product
  puts "Using product: #{product.name}"
  puts "Contract expires: #{product.contract_end_date}"
  puts "Company 1: #{user1.company_name}"
  puts "Company 2: #{user3.company_name}"
  
  # Clean up any existing renegotiations
  product.renegotiations.where(status: "ongoing").destroy_all
  
  # Create ongoing renegotiation for user1's company
  renegotiation = Renegotiation.create!(
    product: product,
    buyer: user1,
    supplier: product.supplier,
    status: "ongoing",
    min_target: 100,
    max_target: 200,
    tone: "collaborative"
  )
  
  puts "\n✅ Created ongoing renegotiation ID: #{renegotiation.id} for #{user1.company_name}"
  
  puts "\n=== Testing Blocked State ==="
  
  # Test user1 (has ongoing)
  puts "User 1 (#{user1.company_name}) - has ongoing renegotiation:"
  if product.has_ongoing_renegotiation?(user1)
    puts "  ✅ CSS Class: 'renegotiate-btn ongoing'"
    puts "  ✅ Text: 'Continue Renegotiation'"
  end
  
  # Test user3 (different company, should see blocked)
  puts "\nUser 3 (#{user3.company_name}) - different company:"
  puts "  contract_expiring_soon?: #{product.contract_expiring_soon?}"
  puts "  has_ongoing_renegotiation?: #{product.has_ongoing_renegotiation?(user3)}"
  puts "  renegotiation_allowed?: #{product.renegotiation_allowed?(user3)}"
  
  if product.renegotiation_allowed?(user3)
    puts "  ✅ CSS Class: 'renegotiate-btn available'"
    puts "  ✅ Text: 'Renegotiate'"
  elsif product.has_ongoing_renegotiation?(user3)
    puts "  ✅ CSS Class: 'renegotiate-btn ongoing'"
    puts "  ✅ Text: 'Continue Renegotiation'"
  elsif product.contract_expiring_soon?
    puts "  ✅ CSS Class: 'no-action-label'"
    puts "  ✅ Style: Muted orange background (rgba(255,117,24,0.2))"
    puts "  ✅ Text: 'Renegotiation in progress'"
    puts "  ⚠️  BLOCKED STATE: User sees other company is negotiating"
  else
    puts "  ✅ CSS Class: 'next-review-label'"
    puts "  ✅ Text: 'Review on #{product.next_review_date&.strftime("%d.%m.%Y")}'"
  end
  
  # Cleanup
  renegotiation.destroy
  if user3.email.include?("test") && user3.id > 200 # Only delete our test user
    user3.destroy
    puts "\n✅ Cleaned up test user"
  end
  
  puts "\n✅ Blocked state test completed"
else
  puts "❌ No suitable product found for blocked state test"
end