class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :name
      t.string :barcode
      t.text :description

      t.timestamps
    end
    add_index :items, :barcode
  end
end
