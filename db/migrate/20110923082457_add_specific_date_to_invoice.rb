class AddSpecificDateToInvoice < ActiveRecord::Migration
  def self.up
    add_column :invoices, :specific_date, :datetime
  end

  def self.down
    remove_column :invoices, :specific_date
  end
end
