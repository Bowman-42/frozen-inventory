class MigrateExistingInventoryToIndividualTracking < ActiveRecord::Migration[8.0]
  def up
    puts "Starting migration of existing inventory to individual tracking..."

    migrated_count = 0
    InventoryItem.includes(:item, :location).find_each do |inventory_item|
      next if inventory_item.quantity <= 0

      if inventory_item.quantity == 1
        # Single items: preserve original barcode
        migrate_single_item_preserve_barcode(inventory_item)
        puts "✓ Preserved barcode #{inventory_item.item.barcode} for #{inventory_item.item.name}"
      else
        # Multiple items: create new individual barcodes
        migrate_multiple_items_new_barcodes(inventory_item)
        puts "✓ Created #{inventory_item.quantity} individual barcodes for #{inventory_item.item.name}"
      end

      migrated_count += 1
    end

    puts "Migration completed: #{migrated_count} inventory items migrated"

    # Validate migration
    validate_migration
  end

  def down
    puts "Rolling back individual tracking migration..."
    IndividualInventoryItem.destroy_all
    ReusableBarcode.destroy_all
    ItemIdCounter.destroy_all
    puts "Rollback completed"
  end

private

  def migrate_single_item_preserve_barcode(inventory_item)
    item = inventory_item.item

    # Create reusable barcode using existing item barcode
    reusable_barcode = ReusableBarcode.create!(
      item: item,
      barcode: item.barcode,
      in_use: true,
      last_used_at: inventory_item.added_at,
      created_at: inventory_item.added_at
    )

    # Create individual inventory item
    IndividualInventoryItem.create!(
      location: inventory_item.location,
      item: item,
      inventory_item: inventory_item,
      reusable_barcode: reusable_barcode,
      sequence_number: 1,
      added_at: inventory_item.added_at
    )

    # Initialize counter starting from 2
    ItemIdCounter.find_or_create_by!(item: item) do |counter|
      counter.last_counter = 1
    end
  end

  def migrate_multiple_items_new_barcodes(inventory_item)
    item = inventory_item.item
    counter = ItemIdCounter.find_or_create_by(item: item)

    inventory_item.quantity.times do |i|
      sequence_number = counter.increment!(:last_counter)
      individual_barcode = "#{item.barcode}-#{sequence_number.to_s.rjust(5, '0')}"

      reusable_barcode = ReusableBarcode.create!(
        item: item,
        barcode: individual_barcode,
        in_use: true,
        last_used_at: inventory_item.added_at + i.minutes,
        created_at: inventory_item.added_at
      )

      IndividualInventoryItem.create!(
        location: inventory_item.location,
        item: item,
        inventory_item: inventory_item,
        reusable_barcode: reusable_barcode,
        sequence_number: sequence_number,
        added_at: inventory_item.added_at + i.minutes
      )
    end
  end

  def validate_migration
    puts "Validating migration..."

    # Check that total quantities match
    Item.find_each do |item|
      old_total = item.inventory_items.sum(:quantity)
      new_total = IndividualInventoryItem.where(item: item).count

      unless old_total == new_total
        raise "Migration validation failed for #{item.name}: old_total=#{old_total}, new_total=#{new_total}"
      end
    end

    # Check that all individual items have valid barcodes
    invalid_count = IndividualInventoryItem.joins(:reusable_barcode)
      .where(reusable_barcodes: { in_use: false }).count

    if invalid_count > 0
      raise "Migration validation failed: #{invalid_count} individual items have unused barcodes"
    end

    puts "✓ Migration validation passed"
  end
end
