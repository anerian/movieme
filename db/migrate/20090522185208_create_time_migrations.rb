class CreateTimeMigrations < ActiveRecord::Migration
  def self.up
    create_table :time_migrations do |t|
      t.timestamps
    end
  end

  def self.down
    drop_table :time_migrations
  end
end
