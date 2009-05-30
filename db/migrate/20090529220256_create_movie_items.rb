class CreateMovieItems < ActiveRecord::Migration
  def self.up
    create_table :movie_items do |t|
      t.integer :last_week
      t.integer :this_week
      t.integer :weeks_released
      
      t.float :weekend_gross
      t.float :theater_average
      
      t.belongs_to :movie
      t.belongs_to :weekend
      
      t.timestamps
    end
    
    add_index :movie_items, [:movie_id, :weekend_id], :unique => true
    
    change_column :movies, :gross, :float
    
    execute('update movies set gross = (gross/1000000)')
    
    add_column :movies, :yid, :integer, :default => nil
    
    execute('update movies set yid = mid')
    
    remove_column :movies, :mid
  end

  def self.down
    drop_table :movie_items
  end
end