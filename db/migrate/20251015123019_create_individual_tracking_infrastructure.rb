class CreateIndividualTrackingInfrastructure < ActiveRecord::Migration[8.0]
  def up
    # Counter management for sequential barcode generation
    create_table :item_id_counters do |t|
      t.references :item, null: false, foreign_key: true, index: { unique: true }
      t.integer :last_counter, default: 0, null: false
      t.timestamps
    end

    # Barcode pool for reuse management
    create_table :reusable_barcodes do |t|
      t.references :item, null: false, foreign_key: true
      t.string :barcode, null: false
      t.boolean :in_use, default: false, null: false
      t.datetime :created_at, null: false
      t.datetime :last_used_at
    end
    add_index :reusable_barcodes, [:item_id, :in_use]
    add_index :reusable_barcodes, :barcode, unique: true

    # Individual item tracking (core table)
    create_table :individual_inventory_items do |t|
      t.references :location, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.references :reusable_barcode, null: false, foreign_key: true
      t.references :inventory_item, null: false, foreign_key: true
      t.integer :sequence_number, null: false
      t.datetime :added_at, null: false
      t.text :notes # Optional: condition, batch info, etc.
      t.timestamps
    end

    # Optimized indexes for common queries
    add_index :individual_inventory_items, :added_at
    add_index :individual_inventory_items, [:location_id, :item_id]
    add_index :individual_inventory_items, [:item_id, :sequence_number], unique: true
    # Note: inventory_item_id index is created automatically by t.references
  end

  def down
    drop_table :individual_inventory_items
    drop_table :reusable_barcodes
    drop_table :item_id_counters
  end
end
