class ChangeTypeInExpenses < ActiveRecord::Migration
  def self.up
    rename_column :expenses, :type, :expense_type
  end

  def self.down
  end
end
