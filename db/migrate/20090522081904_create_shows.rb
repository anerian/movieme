class CreateShows < ActiveRecord::Migration
  def self.up
    create_table :shows do |t|
      t.belongs_to :theater, :null => false
      t.belongs_to :movie, :null => false
      t.text :times
      t.date :date
      t.timestamps
    end
  end

  def self.down
    drop_table :shows
  end
end
