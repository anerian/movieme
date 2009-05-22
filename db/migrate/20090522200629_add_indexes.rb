class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index :shows, [:theater_id, :movie_id, :date], :unique => true
  end

  def self.down
    remove_index :shows, [:theater_id, :movie_id, :date]
  end
end
