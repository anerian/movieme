class CreateReviews < ActiveRecord::Migration
  def self.up
    create_table :reviews do |t|
      t.text :comment
      t.string :author
      t.string :source
      t.integer :rating
      t.date :reviewed_on
      t.belongs_to :movie
      t.timestamps
    end
    
    add_index :reviews, [:author, :source, :movie_id], :unique => true
    
    add_column :movies, :tmeter, :integer, :default => nil
    add_column :movies, :reviews_count, :integer, :default => 0
  end

  def self.down
    drop_table :reviews
    remove_column :movies, :reviews_count
    remove_column :movies, :tmeter
  end
end
