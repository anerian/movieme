class AddAdditionalColumnsToMovie < ActiveRecord::Migration
  def self.up
    add_column :movies, :description,        :text
    add_column :movies, :image_file_name,    :string
    add_column :movies, :image_remote_url,   :string
    add_column :movies, :image_content_type, :string
    add_column :movies, :image_file_size,    :integer
    add_column :movies, :image_updated_at,   :datetime
    
  end

  def self.down
    remove_column :movies, :description
    remove_column :movies, :images_file_name
    remove_column :movies, :image_remote_url
    remove_column :movies, :images_content_type
    remove_column :movies, :images_file_size
    remove_column :movies, :images_updated_at
  end
end
