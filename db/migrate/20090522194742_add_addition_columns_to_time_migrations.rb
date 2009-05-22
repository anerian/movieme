class AddAdditionColumnsToTimeMigrations < ActiveRecord::Migration
  def self.up
    add_column :time_migrations, :date, :date, :null => false
  end

  def self.down
    remove_column :time_migrations
  end
end
