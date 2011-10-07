class CreateQuotationItems < ActiveRecord::Migration
  def self.up
    create_table :quotation_items do |t|
      t.integer :quantity
      t.float :amount
      t.string :description
      t.references :quotation

      t.timestamps
    end
  end

  def self.down
    drop_table :quotation_items
  end
end
