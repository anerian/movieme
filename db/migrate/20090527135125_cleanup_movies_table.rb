class CleanupMoviesTable < ActiveRecord::Migration
  def self.up
    rename_column :movies, :description, :synopsis
    add_column :movies, :distributor, :string
    add_column :movies, :actors, :text
    add_column :movies, :directors, :string
    add_column :movies, :imdbid, :string
    add_column :movies, :gid, :string
    change_column :movies, :released_at, :date
    
    ActiveRecord::Base.connection.execute('update movies set processed = 0')
  end

  def self.down
  end
end
