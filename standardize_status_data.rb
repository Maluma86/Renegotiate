# Standardize status data to consistent capitalization format
puts "=== Standardizing Status Data ==="

puts "\n1. Current Product Status Values:"
Product.distinct.pluck(:status).compact.each do |status|
  count = Product.where(status: status).count
  puts "  '#{status}': #{count} products"
end

puts "\n2. Current Renegotiation Status Values:"
Renegotiation.distinct.pluck(:status).compact.each do |status|
  count = Renegotiation.where(status: status).count
  puts "  '#{status}': #{count} renegotiations"
end

puts "\n=== Standardizing Product Status Values ==="

# Standardize Product status values
status_mapping = {
  "pending" => "Pending",
  "Pending" => "Pending",        # Already correct
  "ongoing" => "Ongoing", 
  "Ongoing" => "Ongoing",        # Already correct
  "done" => "Done",
  "Done" => "Done",              # Already correct
  "human_required" => "Human_Required",
  "Human_required" => "Human_Required",
  "Human required" => "Human_Required"
}

status_mapping.each do |old_status, new_status|
  if old_status != new_status
    count = Product.where(status: old_status).update_all(status: new_status)
    puts "✅ Updated #{count} products from '#{old_status}' to '#{new_status}'"
  end
end

puts "\n=== Standardizing Renegotiation Status Values ==="

# Standardize Renegotiation status values  
renegotiation_status_mapping = {
  "pending" => "Pending",
  "ongoing" => "Ongoing",
  "done" => "Done", 
  "human_required" => "Human_Required",
  "Human required" => "Human_Required",
  "initialized" => "Ongoing"  # Map old "initialized" to "Ongoing"
}

renegotiation_status_mapping.each do |old_status, new_status|
  if old_status != new_status
    count = Renegotiation.where(status: old_status).update_all(status: new_status)
    puts "✅ Updated #{count} renegotiations from '#{old_status}' to '#{new_status}'"
  end
end

puts "\n=== Final Status Values ==="

puts "\nProduct Status Values (after standardization):"
Product.distinct.pluck(:status).compact.sort.each do |status|
  count = Product.where(status: status).count
  puts "  '#{status}': #{count} products"
end

puts "\nRenegotiation Status Values (after standardization):"
Renegotiation.distinct.pluck(:status).compact.sort.each do |status|
  count = Renegotiation.where(status: status).count
  puts "  '#{status}': #{count} renegotiations"
end

puts "\n✅ Status data standardization completed"