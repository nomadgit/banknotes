class AddNameToAdminUser < ActiveRecord::Migration
  def self.up
    add_column :admin_users, :name, :string
  end

  def self.down
    remove_column :admin_users, :name
  end
end
