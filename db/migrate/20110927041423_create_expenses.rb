class CreateExpenses < ActiveRecord::Migration
  def self.up
    create_table :expenses do |t|
      t.string :type
      t.text :detail
      t.float :cost

      t.timestamps
    end
  end

  def self.down
    drop_table :expenses
  end
end
