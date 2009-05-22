class AddProcessColumns < ActiveRecord::Migration
  def self.up    
    add_column :time_migrations, :completed_at, :datetime
    add_column :time_migrations, :last_zip, :string
    
    remove_column :time_migrations, :created_at
    remove_column :time_migrations, :updated_at
  end

  def self.down
  end
end
