namespace :test_data do
  desc "Create test locations (Usage: NR=5 rake test_data:create_locations or rake test_data:create_locations)"
  task :create_locations, [:nr] => :environment do |task, args|
    nr = (ENV['NR'] || args[:nr] || 1).to_i

    puts "Creating #{nr} test location#{'s' if nr > 1}..."

    location_names = [
      "Main Freezer", "Walk-in Cooler", "Display Fridge", "Storage Freezer",
      "Prep Cooler", "Beverage Fridge", "Meat Locker", "Dairy Cooler",
      "Vegetable Cooler", "Emergency Freezer", "Staff Fridge", "Loading Dock Cooler"
    ]

    descriptions = [
      "Primary storage for frozen goods",
      "Temperature controlled storage area",
      "Customer-facing refrigerated display",
      "Long-term frozen storage",
      "Kitchen preparation area cooling",
      "Dedicated beverage storage",
      "Specialized meat storage",
      "Dairy products cooling",
      "Fresh produce storage",
      "Backup freezer unit",
      "Employee break room fridge",
      "Temporary storage during delivery"
    ]

    created_count = 0

    nr.times do |i|
      name = location_names[i % location_names.length]
      # Add number suffix if we're creating more locations than unique names
      name += " #{(i / location_names.length) + 1}" if i >= location_names.length

      description = descriptions[i % descriptions.length]

      location = Location.create!(
        name: name,
        description: description
      )

      created_count += 1
      puts "✅ Created location: #{location.name} (#{location.barcode})"
    rescue ActiveRecord::RecordInvalid => e
      puts "❌ Failed to create location: #{e.message}"
    end

    puts "📊 Successfully created #{created_count} out of #{nr} requested locations"
    puts "📍 Total locations in database: #{Location.count}"
  end

  desc "Create test items (Usage: NR=10 rake test_data:create_items or rake test_data:create_items)"
  task :create_items, [:nr] => :environment do |task, args|
    nr = (ENV['NR'] || args[:nr] || 1).to_i

    puts "Creating #{nr} test item#{'s' if nr > 1}..."

    item_names = [
      "Frozen Pizza", "Ice Cream Vanilla", "Chicken Breast", "Ground Beef",
      "Frozen Vegetables", "Fish Fillets", "Frozen Berries", "Yogurt Cups",
      "Cheese Slices", "Milk Whole", "Butter Sticks", "Frozen Waffles",
      "Turkey Slices", "Frozen Pasta", "Ice Cream Chocolate", "Frozen Corn",
      "Beef Steaks", "Frozen Shrimp", "Cottage Cheese", "Heavy Cream",
      "Frozen Fries", "Breakfast Sausage", "Frozen Spinach", "Mozzarella",
      "Almond Milk", "Frozen Burgers", "Salmon Fillets", "Greek Yogurt",
      "Cheddar Cheese", "Coconut Milk", "Frozen Onions", "Pork Chops"
    ]

    descriptions = [
      "Frozen ready-to-cook meal", "Premium dairy dessert", "Fresh protein source",
      "Ground meat for cooking", "Mixed frozen vegetables", "Fresh fish fillets",
      "Frozen fruit mix", "Individual yogurt servings", "Processed cheese slices",
      "Fresh dairy milk", "Salted butter portions", "Breakfast frozen items",
      "Sliced deli meat", "Frozen pasta meals", "Chocolate flavored dessert",
      "Frozen corn kernels", "Premium beef cuts", "Frozen seafood",
      "Dairy cottage cheese", "Cooking cream", "Frozen potato products",
      "Breakfast meat", "Frozen leafy greens", "Italian cheese",
      "Plant-based milk", "Frozen beef patties", "Fresh salmon cuts",
      "Thick Greek-style yogurt", "Sharp cheddar", "Dairy-free milk alternative",
      "Frozen chopped onions", "Fresh pork cuts"
    ]

    created_count = 0

    nr.times do |i|
      name = item_names[i % item_names.length]
      # Add number suffix if we're creating more items than unique names
      name += " #{(i / item_names.length) + 1}" if i >= item_names.length

      description = descriptions[i % descriptions.length]

      item = Item.create!(
        name: name,
        description: description
      )

      created_count += 1
      puts "✅ Created item: #{item.name} (#{item.barcode})"
    rescue ActiveRecord::RecordInvalid => e
      puts "❌ Failed to create item: #{e.message}"
    end

    puts "📊 Successfully created #{created_count} out of #{nr} requested items"
    puts "📦 Total items in database: #{Item.count}"
  end

  desc "Add items to locations randomly (Usage: NR=20 rake test_data:add_items_to_locations or rake test_data:add_items_to_locations)"
  task :add_items_to_locations, [:nr] => :environment do |task, args|
    nr = (ENV['NR'] || args[:nr] || 1).to_i

    puts "Adding #{nr} item#{'s' if nr > 1} to locations..."

    # Ensure minimum locations exist
    if Location.count < 3
      needed = 3 - Location.count
      puts "⚠️  Only #{Location.count} locations found. Creating #{needed} more locations..."
      Rake::Task['test_data:create_locations'].invoke(needed)
      Rake::Task['test_data:create_locations'].reenable
    end

    # Ensure minimum items exist
    if Item.count < 5
      needed = 5 - Item.count
      puts "⚠️  Only #{Item.count} items found. Creating #{needed} more items..."
      Rake::Task['test_data:create_items'].invoke(needed)
      Rake::Task['test_data:create_items'].reenable
    end

    locations = Location.all.to_a
    items = Item.all.to_a
    created_count = 0
    items_in_multiple_locations = Set.new

    puts "📍 Available locations: #{locations.map(&:name).join(', ')}"
    puts "📦 Available items: #{items.count} items"

    # First, ensure at least one item type is in 2+ locations
    sample_item = items.sample
    selected_locations = locations.sample(2)

    selected_locations.each do |location|
      quantity = rand(1..10)

      inventory_item = InventoryItem.create!(
        location: location,
        item: sample_item,
        quantity: quantity,
        added_at: Time.current - rand(30).days
      )

      items_in_multiple_locations.add(sample_item.id)
      created_count += 1
      puts "✅ Added #{quantity}x #{sample_item.name} to #{location.name}"
    end

    # Add remaining items randomly
    remaining = nr - 2
    remaining.times do
      location = locations.sample
      item = items.sample
      quantity = rand(1..15)

      # Check if this combination already exists
      existing = InventoryItem.find_by(location: location, item: item)
      if existing
        # Update quantity instead
        old_quantity = existing.quantity
        existing.update!(quantity: existing.quantity + quantity)
        puts "📈 Updated #{item.name} in #{location.name}: #{old_quantity} → #{existing.quantity}"
      else
        InventoryItem.create!(
          location: location,
          item: item,
          quantity: quantity,
          added_at: Time.current - rand(30).days
        )
        puts "✅ Added #{quantity}x #{item.name} to #{location.name}"
      end

      created_count += 1
    end

    puts "📊 Successfully processed #{created_count} inventory operations"
    puts "🔄 Items in multiple locations: #{items_in_multiple_locations.size}"
    puts "📦 Total inventory items: #{InventoryItem.count}"

    # Show summary by location
    puts "\n📋 Summary by location:"
    locations.each do |location|
      item_count = location.inventory_items.count
      total_quantity = location.total_items
      puts "  #{location.name}: #{item_count} different items, #{total_quantity} total quantity"
    end
  end

  desc "Show test data statistics"
  task :stats => :environment do
    puts "📊 Test Data Statistics"
    puts "=" * 40
    puts "📍 Locations: #{Location.count}"
    puts "📦 Items: #{Item.count}"
    puts "🔄 Inventory Items: #{InventoryItem.count}"
    puts "💾 Total Quantity: #{InventoryItem.sum(:quantity)}"
    puts ""

    if Location.any?
      puts "📍 Locations:"
      Location.includes(:inventory_items).each do |location|
        puts "  • #{location.name} (#{location.barcode}): #{location.total_items} items"
      end
      puts ""
    end

    if Item.any?
      puts "📦 Items with inventory:"
      Item.joins(:inventory_items).includes(:inventory_items).group(:id).each do |item|
        total = item.inventory_items.sum(:quantity)
        locations = item.inventory_items.includes(:location).map { |ii| ii.location.name }.uniq
        puts "  • #{item.name} (#{item.barcode}): #{total} total in #{locations.join(', ')}"
      end
    end
  end

  desc "Clear all test data"
  task :clear => :environment do
    puts "🗑️  Clearing all test data..."

    InventoryItem.destroy_all
    puts "✅ Cleared #{InventoryItem.count} inventory items"

    Item.destroy_all
    puts "✅ Cleared #{Item.count} items"

    Location.destroy_all
    puts "✅ Cleared #{Location.count} locations"

    puts "🧹 All test data cleared!"
  end
end