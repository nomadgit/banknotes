class CreateQuotations < ActiveRecord::Migration
  def self.up
    create_table :quotations do |t|
      t.string :code
      t.text :notes
      t.text :terms
      t.string :status
      t.float :tax
      t.float :discount
      t.references :client

      t.timestamps
    end
  end

  def self.down
    drop_table :quotations
  end
end
