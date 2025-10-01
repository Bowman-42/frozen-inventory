require 'csv'
require 'ostruct'

namespace :import do
  desc "Import items from CSV file (Usage: FILE=path/to/items.csv rake import:items, add DRY_RUN=true for preview)"
  task :items => :environment do
    file_path = ENV['FILE']
    dry_run = ENV['DRY_RUN'].present? && ENV['DRY_RUN'].downcase != 'false'

    if file_path.blank?
      puts "❌ Error: Please specify a CSV file path using FILE=path/to/items.csv"
      puts "Example: FILE=db/sample_items.csv rake import:items"
      puts "Dry run: FILE=db/sample_items.csv DRY_RUN=true rake import:items"
      exit(1)
    end

    unless File.exist?(file_path)
      puts "❌ Error: File not found: #{file_path}"
      exit(1)
    end

    if dry_run
      puts "🔍 DRY RUN - Previewing import from: #{file_path}"
      puts "No changes will be made to the database"
    else
      puts "📂 Importing items from: #{file_path}"
    end
    puts "=" * 50

    # Statistics
    total_rows = 0
    created_items = 0
    created_categories = 0
    updated_items = 0
    errors = []
    categories_cache = {}

    # Load existing categories into cache
    Category.all.each do |category|
      categories_cache[category.name.downcase] = category
    end

    begin
      CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
        total_rows += 1
        pp row
        # Extract data from CSV row
        name = row[:name]&.strip
        description = row[:description]&.strip
        category_name = row[:category]&.strip

        # Validate required fields
        if name.blank?
          errors << "Row #{total_rows}: Name is required"
          next
        end

        # Handle category
        category = nil
        if category_name.present?
          category_key = category_name.downcase

          # Check if category exists in cache
          unless categories_cache.key?(category_key)
            # Create new category (or simulate in dry run)
            if dry_run
              # Simulate category creation
              categories_cache[category_key] = OpenStruct.new(name: category_name, id: -1)
              created_categories += 1
              puts "🔍 [DRY RUN] Would create new category: #{category_name}"
            else
              begin
                category = Category.create!(
                  name: category_name,
                  description: "Auto-created from CSV import"
                )
                categories_cache[category_key] = category
                created_categories += 1
                puts "✅ Created new category: #{category_name}"
              rescue ActiveRecord::RecordInvalid => e
                errors << "Row #{total_rows}: Failed to create category '#{category_name}': #{e.message}"
                next
              end
            end
          else
            category = categories_cache[category_key]
          end
        end

        # Check if item already exists by name and category
        existing_item = Item.find_by(name: name, category: category)

        begin
          if existing_item
            # Update existing item (only if name and category match)
            if dry_run
              puts "🔍 [DRY RUN] Would update existing item: #{name} [#{category&.name || 'Uncategorized'}]"
            else
              existing_item.update!(description: description)
              puts "🔄 Updated item: #{name} [#{category&.name || 'Uncategorized'}]"
            end
            updated_items += 1
          else
            # Create new item
            if dry_run
              puts "🔍 [DRY RUN] Would create new item: #{name} [#{category&.name || 'Uncategorized'}]"
            else
              item = Item.create!(
                name: name,
                description: description,
                category: category
              )
              puts "✅ Created item: #{name} (#{item.barcode}) [#{category&.name || 'Uncategorized'}]"
            end
            created_items += 1
          end
        rescue ActiveRecord::RecordInvalid => e
          errors << "Row #{total_rows}: Failed to save item '#{name}': #{e.message}"
        end
      end

    rescue CSV::MalformedCSVError => e
      puts "❌ Error reading CSV file: #{e.message}"
      exit(1)
    rescue => e
      puts "❌ Unexpected error: #{e.message}"
      puts e.backtrace
      exit(1)
    end

    # Print summary
    puts "=" * 50
    puts "📊 Import Summary:"
    puts "  📋 Total rows processed: #{total_rows}"
    puts "  ✅ Items created: #{created_items}"
    puts "  🔄 Items updated: #{updated_items}"
    puts "  🏷️  Categories created: #{created_categories}"
    puts "  ❌ Errors: #{errors.count}"

    if errors.any?
      puts ""
      puts "🚨 Error Details:"
      errors.each { |error| puts "  • #{error}" }
    end

    puts ""
    puts "📦 Database totals after import:"
    puts "  • Items: #{Item.count}"
    puts "  • Categories: #{Category.count}"
    puts ""
    puts "🎉 Import completed!"
  end

  desc "Export items to CSV file (Usage: FILE=path/to/export.csv rake import:export)"
  task :export => :environment do
    file_path = ENV['FILE']

    if file_path.blank?
      puts "❌ Error: Please specify a CSV file path using FILE=path/to/export.csv"
      puts "Example: FILE=db/exported_items.csv rake import:export"
      exit(1)
    end

    # Ensure directory exists
    FileUtils.mkdir_p(File.dirname(file_path))

    puts "📤 Exporting items to: #{file_path}"
    puts "=" * 50

    # Statistics
    exported_count = 0

    begin
      CSV.open(file_path, 'w', write_headers: true, headers: ['name', 'description', 'category']) do |csv|
        Item.includes(:category).order(:name).find_each do |item|
          csv << [
            item.name,
            item.description,
            item.category&.name
          ]
          exported_count += 1

          if exported_count % 100 == 0
            puts "📦 Exported #{exported_count} items..."
          end
        end
      end

      puts "=" * 50
      puts "📊 Export Summary:"
      puts "  📋 Total items exported: #{exported_count}"
      puts "  📂 File saved to: #{file_path}"
      puts ""
      puts "🎉 Export completed successfully!"

    rescue => e
      puts "❌ Error during export: #{e.message}"
      puts e.backtrace
      exit(1)
    end
  end

  desc "Show expected CSV format for items import"
  task :format => :environment do
    puts "📋 Expected CSV Format for Items Import"
    puts "=" * 50
    puts ""
    puts "Required headers (case-insensitive):"
    puts "  • name        - Item name (required)"
    puts "  • description - Item description (optional)"
    puts "  • category    - Category name (optional, will be created if doesn't exist)"
    puts ""
    puts "Example CSV content:"
    puts "name,description,category"
    puts "\"Frozen Pizza\",\"Pepperoni pizza ready to cook\",\"Frozen Foods\""
    puts "\"Whole Milk\",\"1 gallon whole milk\",\"Dairy Products\""
    puts "\"Greek Yogurt\",\"Plain Greek yogurt\",\"Dairy Products\""
    puts "\"Salmon Fillet\",\"Fresh Atlantic salmon\",\"Seafood\""
    puts ""
    puts "💡 Tips:"
    puts "  • Categories will be automatically created if they don't exist"
    puts "  • Items with duplicate names will be updated, not duplicated"
    puts "  • Barcodes are automatically generated"
    puts "  • Use quotes around values that contain commas"
    puts ""
    puts "Usage: FILE=path/to/items.csv rake import:items"
    puts "Export: FILE=path/to/export.csv rake import:export"
  end
end