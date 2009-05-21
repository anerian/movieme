class CreateTheaters < ActiveRecord::Migration
  def self.up
    create_table :theaters do |t|
      t.string :name
      t.string :street
      t.string :city
      t.string :state
      t.string :zip
      t.string :phone
      t.decimal :latitude, :precision => 15, :scale => 10
      t.decimal :longitude, :precision => 15, :scale => 10
      t.integer :yid
      
      t.timestamps
    end
    
    add_index :theaters, :yid, :unique => true
  end

  def self.down
    drop_table :theaters
  end
end