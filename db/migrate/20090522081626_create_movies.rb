class CreateMovies < ActiveRecord::Migration
  def self.up
    create_table :movies do |t|
      t.string :title, :null => false
      t.string :rating
      t.integer :duration
      t.integer :mid, :null => false
      t.boolean :processed, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :movies
  end
end
