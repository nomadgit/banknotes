class AddAdminUserIdToExpense < ActiveRecord::Migration
  def self.up
    add_column :expenses, :admin_user_id, :integer
  end

  def self.down
    remove_column :expenses, :admin_user_id
  end
end
