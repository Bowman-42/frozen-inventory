class AddTotalQuantityToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :total_quantity, :integer, default: 0, null: false
    add_index :items, :total_quantity
  end
end
