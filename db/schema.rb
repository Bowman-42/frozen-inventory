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

ActiveRecord::Schema[8.0].define(version: 2025_10_01_130135) do
  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
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

  add_foreign_key "inventory_items", "items"
  add_foreign_key "inventory_items", "locations"
  add_foreign_key "items", "categories"
end
