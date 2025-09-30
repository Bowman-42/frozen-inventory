class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :name
      t.string :barcode
      t.text :description

      t.timestamps
    end
    add_index :locations, :barcode
  end
end
