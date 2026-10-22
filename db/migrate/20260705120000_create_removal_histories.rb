class CreateRemovalHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :removal_histories do |t|
      t.references :item, foreign_key: true
      t.string :item_name, null: false
      t.string :item_barcode, null: false
      t.references :location, foreign_key: true
      t.string :location_name, null: false
      t.string :individual_barcode, null: false
      t.datetime :added_at, null: false
      t.datetime :removed_at, null: false
      t.float :storage_days, null: false
      t.string :removal_method, null: false

      t.timestamps
    end

    add_index :removal_histories, :removed_at
    add_index :removal_histories, :removal_method
  end
end
