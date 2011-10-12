class ChangeDataTypeForQuotationItemDescription < ActiveRecord::Migration
  def self.up
    change_table :quotation_items do |t|
      t.change :description, :text, :limit => nil
    end
  end

  def self.down
    change_table :quotation_items do |t|
      t.change :description, :string
    end
  end
end
