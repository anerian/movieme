class AddTrailerUrlToMovies < ActiveRecord::Migration
  def self.up
    add_column :movies, :trailer_url, :string
  end

  def self.down
    remove_column :movies, :trailer_url
  end
end
