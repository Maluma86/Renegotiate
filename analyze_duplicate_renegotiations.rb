#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "=== Renegotiation Duplicate Analysis ==="
puts "Date: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
puts

# Total renegotiations count
total_renegotiations = Renegotiation.count
puts "📊 Total renegotiations in database: #{total_renegotiations}"
puts

# Status distribution
puts "📈 Status Distribution:"
status_counts = Renegotiation.group(:status).count
status_counts.each do |status, count|
  puts "  #{status}: #{count}"
end
puts

# Look for potential duplicates by product_id + buyer_id + status
puts "🔍 Analyzing potential duplicates (same product + buyer + status):"
duplicate_groups = Renegotiation.group(:product_id, :buyer_id, :status).count.select { |k, v| v > 1 }

if duplicate_groups.empty?
  puts "  ✅ No exact duplicates found (same product + buyer + status)"
else
  puts "  ❌ Found #{duplicate_groups.size} duplicate combinations:"
  duplicate_groups.each do |(product_id, buyer_id, status), count|
    puts "    Product #{product_id} + Buyer #{buyer_id} + Status '#{status}': #{count} records"
  end
end
puts

# Look for multiple ongoing renegotiations (business rule violation)
puts "🚨 Checking for multiple ongoing renegotiations per product+buyer:"
ongoing_duplicates = Renegotiation.where(status: 'Ongoing')
                                  .group(:product_id, :buyer_id)
                                  .count
                                  .select { |k, v| v > 1 }

if ongoing_duplicates.empty?
  puts "  ✅ No multiple ongoing renegotiations found"
else
  puts "  ❌ Found #{ongoing_duplicates.size} violations of business rule:"
  ongoing_duplicates.each do |(product_id, buyer_id), count|
    puts "    Product #{product_id} + Buyer #{buyer_id}: #{count} ongoing renegotiations"
    
    # Show details
    records = Renegotiation.where(product_id: product_id, buyer_id: buyer_id, status: 'Ongoing')
    records.each do |r|
      puts "      ID: #{r.id}, Created: #{r.created_at.strftime('%Y-%m-%d %H:%M')}"
    end
  end
end
puts

# Company-level analysis
puts "🏢 Company-level ongoing renegotiation analysis:"
company_ongoing = Renegotiation.joins(:buyer)
                               .where(status: 'Ongoing')
                               .group('users.company_name, renegotiations.product_id')
                               .count
                               .select { |k, v| v > 1 }

if company_ongoing.empty?
  puts "  ✅ No multiple ongoing renegotiations per company+product"
else
  puts "  ❌ Found #{company_ongoing.size} company-level violations:"
  company_ongoing.each do |(company_name, product_id), count|
    puts "    Company '#{company_name}' + Product #{product_id}: #{count} ongoing renegotiations"
  end
end
puts

# Recent duplicates (created in last 24 hours)
puts "⏰ Recent renegotiations (last 24 hours):"
recent = Renegotiation.where('created_at > ?', 24.hours.ago)
                      .order(created_at: :desc)

if recent.empty?
  puts "  No renegotiations created in last 24 hours"
else
  puts "  Found #{recent.count} recent renegotiations:"
  recent.each do |r|
    buyer_company = r.buyer.company_name
    product_name = r.product.name
    puts "    ID: #{r.id}, Status: #{r.status}, Company: #{buyer_company}, Product: #{product_name}, Created: #{r.created_at.strftime('%Y-%m-%d %H:%M')}"
  end
end
puts

# Summary and recommendations
puts "📋 SUMMARY:"
puts "  Total renegotiations: #{total_renegotiations}"
puts "  Exact duplicates: #{duplicate_groups.size}"
puts "  Ongoing duplicates: #{ongoing_duplicates.size}"
puts "  Company-level duplicates: #{company_ongoing.size}"
puts "  Recent activity: #{recent.count}"
puts

if duplicate_groups.any? || ongoing_duplicates.any? || company_ongoing.any?
  puts "🛠️  RECOMMENDED ACTIONS:"
  puts "  1. Review and merge duplicate records"
  puts "  2. Keep the oldest record, update references"
  puts "  3. Delete newer duplicate records"
  puts "  4. Verify unique constraint is working"
else
  puts "✅ NO CLEANUP NEEDED - Database is clean!"
end

puts
puts "=== Analysis Complete ==="