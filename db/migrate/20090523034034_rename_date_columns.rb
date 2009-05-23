class RenameDateColumns < ActiveRecord::Migration
  def self.up
    rename_column :time_migrations, :date, :migrated_at
    rename_column :shows, :date, :shown_on
  end

  def self.down
  end
end
