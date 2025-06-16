# Test CSS rendering and asset compilation
puts "=== Testing CSS Rendering and Asset Compilation ==="

# Check if CSS file exists and contains our styles
css_file = "app/assets/stylesheets/components/_products_index.scss"
if File.exist?(css_file)
  puts "✅ CSS file exists: #{css_file}"
  
  content = File.read(css_file)
  
  # Check for our button state styles
  styles_to_check = [
    "&.available",
    "&.ongoing", 
    "background-color: #1e40af",
    ".no-action-label",
    ".next-review-label",
    "rgba(255, 117, 24, 0.2)",
    "rgba(59, 130, 246, 0.2)"
  ]
  
  puts "\n🎨 CSS Style Verification:"
  styles_to_check.each do |style|
    if content.include?(style)
      puts "  ✅ #{style}"
    else
      puts "  ❌ #{style} - missing"
    end
  end
  
else
  puts "❌ CSS file not found: #{css_file}"
end

# Check application.scss imports our component
app_css = "app/assets/stylesheets/application.scss"
if File.exist?(app_css)
  app_content = File.read(app_css)
  if app_content.include?("products_index")
    puts "\n✅ products_index component imported in application.scss"
  else
    puts "\n❌ products_index component NOT imported in application.scss"
  end
end

# Test asset compilation by checking for syntax errors
puts "\n🔧 Testing Asset Compilation:"
begin
  # Try to precompile assets to check for syntax errors
  result = `cd /Users/user/Desktop/renegotiate && rails assets:precompile RAILS_ENV=development 2>&1`
  if $?.success?
    puts "✅ Assets compile successfully"
  else
    puts "❌ Asset compilation failed:"
    puts result.split("\n").last(5).join("\n")
  end
rescue => e
  puts "❌ Error testing asset compilation: #{e.message}"
end

# Create a simple test product scenario for browser testing
user = User.where(role: "procurement").first
product = Product.first

puts "\n🌐 Browser Testing Setup:"
puts "Server running at: http://localhost:3000"
puts "Test user: #{user.email}"
puts "Test product: #{product.name}"
puts "Contract expires: #{product.contract_end_date}"
puts "Expected button state: #{product.renegotiation_allowed?(user) ? 'available' : 'other'}"

puts "\n📱 UI Testing Checklist:"
puts "  □ Navigate to http://localhost:3000/products"
puts "  □ Login with user: #{user.email}"
puts "  □ Verify button styles display correctly:"
puts "    □ Orange 'Renegotiate' buttons (available state)"
puts "    □ Blue 'Continue Renegotiation' buttons (ongoing state)"
puts "    □ Muted labels for non-actionable states"
puts "  □ Test hover effects on buttons"
puts "  □ Verify responsive design on different screen sizes"

puts "\n✅ CSS Rendering Test Completed"