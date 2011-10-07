class AddSpecificDateToQuotation < ActiveRecord::Migration
  def self.up
    add_column :quotations, :specific_date, :datetime
  end

  def self.down
    remove_column :quotations, :specific_date
  end
end
