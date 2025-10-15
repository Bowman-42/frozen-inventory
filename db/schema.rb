# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_15_123702) do
  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "individual_inventory_items", force: :cascade do |t|
    t.integer "location_id", null: false
    t.integer "item_id", null: false
    t.integer "reusable_barcode_id", null: false
    t.integer "inventory_item_id", null: false
    t.integer "sequence_number", null: false
    t.datetime "added_at", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["added_at"], name: "index_individual_inventory_items_on_added_at"
    t.index ["inventory_item_id"], name: "index_individual_inventory_items_on_inventory_item_id"
    t.index ["item_id", "sequence_number"], name: "idx_on_item_id_sequence_number_0c64e8c101", unique: true
    t.index ["item_id"], name: "index_individual_inventory_items_on_item_id"
    t.index ["location_id", "item_id"], name: "index_individual_inventory_items_on_location_id_and_item_id"
    t.index ["location_id"], name: "index_individual_inventory_items_on_location_id"
    t.index ["reusable_barcode_id"], name: "index_individual_inventory_items_on_reusable_barcode_id"
  end

  create_table "inventory_items", force: :cascade do |t|
    t.integer "location_id", null: false
    t.integer "item_id", null: false
    t.integer "quantity"
    t.datetime "added_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_inventory_items_on_item_id"
    t.index ["location_id"], name: "index_inventory_items_on_location_id"
  end

  create_table "item_id_counters", force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "last_counter", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_item_id_counters_on_item_id", unique: true
  end

  create_table "items", force: :cascade do |t|
    t.string "name"
    t.string "barcode"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "total_quantity", default: 0, null: false
    t.integer "category_id"
    t.index ["barcode"], name: "index_items_on_barcode"
    t.index ["category_id"], name: "index_items_on_category_id"
    t.index ["total_quantity"], name: "index_items_on_total_quantity"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.string "barcode"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["barcode"], name: "index_locations_on_barcode"
  end

  create_table "reusable_barcodes", force: :cascade do |t|
    t.integer "item_id", null: false
    t.string "barcode", null: false
    t.boolean "in_use", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "last_used_at"
    t.index ["barcode"], name: "index_reusable_barcodes_on_barcode", unique: true
    t.index ["item_id", "in_use"], name: "index_reusable_barcodes_on_item_id_and_in_use"
    t.index ["item_id"], name: "index_reusable_barcodes_on_item_id"
  end

  add_foreign_key "individual_inventory_items", "inventory_items"
  add_foreign_key "individual_inventory_items", "items"
  add_foreign_key "individual_inventory_items", "locations"
  add_foreign_key "individual_inventory_items", "reusable_barcodes"
  add_foreign_key "inventory_items", "items"
  add_foreign_key "inventory_items", "locations"
  add_foreign_key "item_id_counters", "items"
  add_foreign_key "items", "categories"
  add_foreign_key "reusable_barcodes", "items"
end
