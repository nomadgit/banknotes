class AddContactPointIdToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :contact_point, :text
  end

  def self.down
    remove_column :clients, :contact_point
  end
end
