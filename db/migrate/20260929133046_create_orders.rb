class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.string :customer_name, null: false
      t.string :customer_phone, null: false
      t.integer :order_type, null: false
      t.string :delivery_address
      t.integer :total_clp, null: false
      t.integer :dispatch_status, null: false, default: 0
      t.datetime :dispatched_at
      t.text :dispatch_error

      t.timestamps
    end
  end
end
