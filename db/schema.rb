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

ActiveRecord::Schema[8.0].define(version: 2025_09_30_164204) do
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
    t.index ["barcode"], name: "index_items_on_barcode"
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
end
