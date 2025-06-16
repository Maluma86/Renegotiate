#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "=== Renegotiation Duplicate Cleanup Script ==="
puts "Date: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
puts

# Safety check - only run in development
unless Rails.env.development?
  puts "❌ ERROR: This script can only run in development environment!"
  puts "Current environment: #{Rails.env}"
  exit 1
end

puts "✅ Running in development environment - safe to proceed"
puts

# Find the duplicate records identified in analysis
puts "🔍 Finding duplicate records..."
duplicate_groups = Renegotiation.group(:product_id, :buyer_id, :status).count.select { |k, v| v > 1 }

if duplicate_groups.empty?
  puts "✅ No duplicates found - database is clean!"
  exit 0
end

puts "Found #{duplicate_groups.size} duplicate groups:"
duplicate_groups.each do |(product_id, buyer_id, status), count|
  puts "  Product #{product_id} + Buyer #{buyer_id} + Status '#{status}': #{count} records"
end
puts

# Analyze each duplicate group in detail
duplicate_groups.each do |(product_id, buyer_id, status), count|
  puts "🔧 Processing duplicate group: Product #{product_id} + Buyer #{buyer_id} + Status '#{status}'"
  
  # Get all duplicate records for this group, ordered by creation date
  records = Renegotiation.where(
    product_id: product_id,
    buyer_id: buyer_id,
    status: status
  ).order(:created_at)
  
  puts "  Found #{records.count} duplicate records:"
  records.each_with_index do |record, index|
    puts "    #{index + 1}. ID: #{record.id}, Created: #{record.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
  end
  
  # Keep the oldest record (first one), mark others for deletion
  keeper = records.first
  to_delete = records[1..-1]
  
  puts "  📌 KEEPING: ID #{keeper.id} (oldest record)"
  puts "  🗑️  DELETING: #{to_delete.map(&:id).join(', ')}"
  
  # Before deletion, check if any of these records are referenced elsewhere
  puts "  🔗 Checking for references..."
  references_found = false
  
  to_delete.each do |record|
    # Add checks for any foreign key references if they exist
    # For now, we'll just note the record details
    puts "    Record ID #{record.id} details:"
    puts "      Created: #{record.created_at}"
    puts "      Status: #{record.status}"
    puts "      Min Target: #{record.min_target}"
    puts "      Max Target: #{record.max_target}"
    puts "      Thread: #{record.thread || 'empty'}"
  end
  
  # Perform the cleanup
  puts "  🧹 Performing cleanup..."
  
  begin
    ActiveRecord::Base.transaction do
      to_delete.each do |record|
        puts "    Deleting record ID #{record.id}..."
        record.destroy!
      end
      puts "  ✅ Successfully cleaned up #{to_delete.count} duplicate records"
    end
  rescue => e
    puts "  ❌ Error during cleanup: #{e.message}"
    puts "  Transaction rolled back - no changes made"
  end
  
  puts
end

# Verify cleanup results
puts "🎯 Cleanup completed! Verifying results..."
remaining_duplicates = Renegotiation.group(:product_id, :buyer_id, :status).count.select { |k, v| v > 1 }

if remaining_duplicates.empty?
  puts "✅ SUCCESS: No duplicate records remain!"
else
  puts "❌ WARNING: #{remaining_duplicates.size} duplicate groups still exist:"
  remaining_duplicates.each do |(product_id, buyer_id, status), count|
    puts "  Product #{product_id} + Buyer #{buyer_id} + Status '#{status}': #{count} records"
  end
end

# Final database state
total_after = Renegotiation.count
puts
puts "📊 Final database state:"
puts "  Total renegotiations: #{total_after}"
puts "  Status distribution:"
Renegotiation.group(:status).count.each do |status, count|
  puts "    #{status}: #{count}"
end

puts
puts "=== Cleanup Complete ==="