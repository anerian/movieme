class AddAdditionalMovieColumns < ActiveRecord::Migration
  def self.up
    add_column :movies, :released_at, :datetime
    add_column :movies, :duration, :integer
    add_column :movies, :gross, :integer
  end

  def self.down
    remove_column :movies, :released_at
    remove_column :movies, :duration
    remove_column :movies, :gross
  end
end
