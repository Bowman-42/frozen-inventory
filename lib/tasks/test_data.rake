namespace :test_data do
  desc "Create test categories (Usage: NR=5 rake test_data:create_categories or rake test_data:create_categories)"
  task :create_categories, [:nr] => :environment do |task, args|
    nr = (ENV['NR'] || args[:nr] || 1).to_i

    puts "Creating #{nr} test categor#{'ies' if nr > 1}#{nr == 1 ? 'y' : ''}..."

    category_data = [
      { name: "Frozen Foods", description: "Frozen meals, vegetables, and prepared foods" },
      { name: "Dairy Products", description: "Milk, cheese, yogurt, and other dairy items" },
      { name: "Meat & Poultry", description: "Fresh and frozen meat and poultry products" },
      { name: "Seafood", description: "Fresh and frozen fish and seafood" },
      { name: "Beverages", description: "Milk, juices, and other cold beverages" },
      { name: "Desserts", description: "Ice cream, frozen desserts, and sweet treats" },
      { name: "Vegetables", description: "Fresh and frozen vegetables" },
      { name: "Fruits", description: "Fresh and frozen fruits and berries" },
      { name: "Breakfast Items", description: "Breakfast foods, cereals, and morning items" },
      { name: "Snacks", description: "Frozen snacks and quick meal items" },
      { name: "Condiments", description: "Sauces, dressings, and condiments requiring refrigeration" },
      { name: "Plant-Based", description: "Vegan and vegetarian alternatives" }
    ]

    created_count = 0

    nr.times do |i|
      data = category_data[i % category_data.length]
      name = data[:name]
      description = data[:description]

      # Add number suffix if we're creating more categories than unique names
      if i >= category_data.length
        suffix = (i / category_data.length) + 1
        name += " #{suffix}"
        description += " (Group #{suffix})"
      end

      category = Category.create!(
        name: name,
        description: description
      )

      created_count += 1
      puts "✅ Created category: #{category.name}"
    rescue ActiveRecord::RecordInvalid => e
      puts "❌ Failed to create category: #{e.message}"
    end

    puts "📊 Successfully created #{created_count} out of #{nr} requested categories"
    puts "🏷️  Total categories in database: #{Category.count}"
  end
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

    # Ensure we have some categories
    if Category.count == 0
      puts "⚠️  No categories found. Creating default categories..."
      Rake::Task['test_data:create_categories'].invoke(6)
      Rake::Task['test_data:create_categories'].reenable
    end

    # Map items to appropriate categories
    item_data = [
      { name: "Frozen Pizza", description: "Frozen ready-to-cook meal", category: "Frozen Foods" },
      { name: "Ice Cream Vanilla", description: "Premium dairy dessert", category: "Desserts" },
      { name: "Chicken Breast", description: "Fresh protein source", category: "Meat & Poultry" },
      { name: "Ground Beef", description: "Ground meat for cooking", category: "Meat & Poultry" },
      { name: "Frozen Vegetables", description: "Mixed frozen vegetables", category: "Vegetables" },
      { name: "Fish Fillets", description: "Fresh fish fillets", category: "Seafood" },
      { name: "Frozen Berries", description: "Frozen fruit mix", category: "Fruits" },
      { name: "Yogurt Cups", description: "Individual yogurt servings", category: "Dairy Products" },
      { name: "Cheese Slices", description: "Processed cheese slices", category: "Dairy Products" },
      { name: "Milk Whole", description: "Fresh dairy milk", category: "Beverages" },
      { name: "Butter Sticks", description: "Salted butter portions", category: "Dairy Products" },
      { name: "Frozen Waffles", description: "Breakfast frozen items", category: "Breakfast Items" },
      { name: "Turkey Slices", description: "Sliced deli meat", category: "Meat & Poultry" },
      { name: "Frozen Pasta", description: "Frozen pasta meals", category: "Frozen Foods" },
      { name: "Ice Cream Chocolate", description: "Chocolate flavored dessert", category: "Desserts" },
      { name: "Frozen Corn", description: "Frozen corn kernels", category: "Vegetables" },
      { name: "Beef Steaks", description: "Premium beef cuts", category: "Meat & Poultry" },
      { name: "Frozen Shrimp", description: "Frozen seafood", category: "Seafood" },
      { name: "Cottage Cheese", description: "Dairy cottage cheese", category: "Dairy Products" },
      { name: "Heavy Cream", description: "Cooking cream", category: "Dairy Products" },
      { name: "Frozen Fries", description: "Frozen potato products", category: "Snacks" },
      { name: "Breakfast Sausage", description: "Breakfast meat", category: "Breakfast Items" },
      { name: "Frozen Spinach", description: "Frozen leafy greens", category: "Vegetables" },
      { name: "Mozzarella", description: "Italian cheese", category: "Dairy Products" },
      { name: "Almond Milk", description: "Plant-based milk", category: "Plant-Based" },
      { name: "Frozen Burgers", description: "Frozen beef patties", category: "Meat & Poultry" },
      { name: "Salmon Fillets", description: "Fresh salmon cuts", category: "Seafood" },
      { name: "Greek Yogurt", description: "Thick Greek-style yogurt", category: "Dairy Products" },
      { name: "Cheddar Cheese", description: "Sharp cheddar", category: "Dairy Products" },
      { name: "Coconut Milk", description: "Dairy-free milk alternative", category: "Plant-Based" },
      { name: "Frozen Onions", description: "Frozen chopped onions", category: "Vegetables" },
      { name: "Pork Chops", description: "Fresh pork cuts", category: "Meat & Poultry" }
    ]

    categories_map = Category.all.index_by(&:name)
    created_count = 0

    nr.times do |i|
      data = item_data[i % item_data.length]
      name = data[:name]
      description = data[:description]
      category_name = data[:category]

      # Add number suffix if we're creating more items than unique names
      if i >= item_data.length
        suffix = (i / item_data.length) + 1
        name += " #{suffix}"
      end

      # Find the category
      category = categories_map[category_name]

      item = Item.create!(
        name: name,
        description: description,
        category: category
      )

      created_count += 1
      category_display = category ? " [#{category.name}]" : " [Uncategorized]"
      puts "✅ Created item: #{item.name} (#{item.barcode})#{category_display}"
    rescue ActiveRecord::RecordInvalid => e
      puts "❌ Failed to create item: #{e.message}"
    end

    puts "📊 Successfully created #{created_count} out of #{nr} requested items"
    puts "📦 Total items in database: #{Item.count}"
    puts "🏷️  Items by category:"
    Category.joins(:items).group('categories.name').count.each do |category_name, count|
      puts "  • #{category_name}: #{count} items"
    end
    uncategorized_count = Item.where(category: nil).count
    puts "  • Uncategorized: #{uncategorized_count} items" if uncategorized_count > 0
  end

  desc "Add items to locations with realistic storage ages (Usage: NR=20 rake test_data:add_items_to_locations)"
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
      days_ago = generate_storage_age

      inventory_item = InventoryItem.create!(
        location: location,
        item: sample_item,
        quantity: quantity,
        added_at: Time.current - days_ago.days
      )

      items_in_multiple_locations.add(sample_item.id)
      created_count += 1
      storage_info = format_storage_info(days_ago)
      puts "✅ Added #{quantity}x #{sample_item.name} to #{location.name}#{storage_info}"
    end

    # Add remaining items randomly
    remaining = nr - 2
    remaining.times do
      location = locations.sample
      item = items.sample
      quantity = rand(1..15)
      days_ago = generate_storage_age

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
          added_at: Time.current - days_ago.days
        )
        storage_info = format_storage_info(days_ago)
        puts "✅ Added #{quantity}x #{item.name} to #{location.name}#{storage_info}"
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
    puts "🏷️  Categories: #{Category.count}"
    puts "📦 Items: #{Item.count}"
    puts "🔄 Inventory Items: #{InventoryItem.count}"
    puts "💾 Total Quantity: #{InventoryItem.sum(:quantity)}"
    puts ""

    if Category.any?
      puts "🏷️  Categories:"
      Category.includes(:items).each do |category|
        puts "  • #{category.name}: #{category.items.count} items"
      end
      uncategorized_count = Item.where(category: nil).count
      puts "  • Uncategorized: #{uncategorized_count} items" if uncategorized_count > 0
      puts ""
    end

    if Location.any?
      puts "📍 Locations:"
      Location.includes(:inventory_items).each do |location|
        puts "  • #{location.name} (#{location.barcode}): #{location.total_items} items"
      end
      puts ""
    end

    if Item.any?
      puts "📦 Items with inventory:"
      Item.joins(:inventory_items).includes(:inventory_items, :category).group(:id).each do |item|
        total = item.inventory_items.sum(:quantity)
        locations = item.inventory_items.includes(:location).map { |ii| ii.location.name }.uniq
        category_info = item.category ? " [#{item.category.name}]" : " [Uncategorized]"
        puts "  • #{item.name} (#{item.barcode})#{category_info}: #{total} total in #{locations.join(', ')}"
      end
    end
  end

  desc "Clear only inventory items and reset item quantities (keeps items, locations, categories)"
  task :clear_inventory => :environment do
    puts "🗑️  Clearing inventory items only..."

    # Get count before clearing
    inventory_count = InventoryItem.count
    item_count = Item.count

    # Clear all inventory items
    InventoryItem.destroy_all
    puts "✅ Cleared #{inventory_count} inventory items"

    # Reset all item total_quantity to 0
    Item.update_all(total_quantity: 0)
    puts "✅ Reset total_quantity to 0 for #{item_count} items"

    puts "🧹 Inventory cleared! Items, locations, and categories preserved."
    puts "📊 Remaining data:"
    puts "  📍 Locations: #{Location.count}"
    puts "  🏷️  Categories: #{Category.count}"
    puts "  📦 Items: #{Item.count}"
    puts "  🔄 Inventory Items: #{InventoryItem.count}"
  end

  desc "Clear all test data"
  task :clear => :environment do
    puts "🗑️  Clearing all test data..."

    InventoryItem.destroy_all
    puts "✅ Cleared inventory items"

    Item.destroy_all
    puts "✅ Cleared items"

    Location.destroy_all
    puts "✅ Cleared locations"

    Category.destroy_all
    puts "✅ Cleared categories"

    puts "🧹 All test data cleared!"
  end

  # Helper methods for generating realistic storage ages
  def generate_storage_age
    # Distribution of storage ages to test all badge colors:
    # 60% recent (0-119 days) - green badges
    # 25% warning (120-180 days) - yellow badges
    # 15% danger (181-365 days) - red badges

    rand_value = rand(100)

    case rand_value
    when 0..59
      # Recent items (green badges)
      rand(0..119)
    when 60..84
      # Warning items (yellow badges)
      rand(120..180)
    else
      # Danger items (red badges)
      rand(181..365)
    end
  end

  def format_storage_info(days_ago)
    case days_ago
    when 0..119
      " (#{days_ago} days ago - fresh)"
    when 120..180
      " (#{days_ago} days ago - ⚠️ getting old)"
    else
      " (#{days_ago} days ago - 🚨 very old)"
    end
  end
end