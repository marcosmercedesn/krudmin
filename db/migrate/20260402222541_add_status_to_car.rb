class AddStatusToCar < ActiveRecord::Migration[8.0]
  def change
    add_column :cars, :status, :integer, default: 0, null: false
    add_index :cars, :status
  end
end
