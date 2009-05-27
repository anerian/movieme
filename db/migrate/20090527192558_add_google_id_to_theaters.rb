class AddGoogleIdToTheaters < ActiveRecord::Migration
  def self.up
    add_column :theaters, :gid, :string
    add_index :theaters, :gid
  end

  def self.down
    remove_column :theaters, :gid
  end
end
