class AddImdbIdToTheaters < ActiveRecord::Migration
  def self.up
    add_column :theaters, :imdbid, :integer, :default => nil
    add_column :theaters, :group, :string
  end

  def self.down
    remove_column :theaters, :imdbid
    remove_column :theaters, :group
  end
end
