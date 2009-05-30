class CreateZipCodes < ActiveRecord::Migration
  def self.up
    create_table :zip_codes do |t|
      t.string :code
      t.decimal :latitude, :precision => 15, :scale => 10
      t.decimal :longitude, :precision => 15, :scale => 10
    end
    
    add_index :zip_codes, :code, :unique => true
    
    execute_sql_from_file("#{ RAILS_ROOT }/db/data/zip_codes.sql")
  end

  def self.down
    drop_table :zip_codes
  end
  
  protected
  
    def self.execute_sql_from_file(file)
      say_with_time("Executing SQL from #{ file }") do
        IO.readlines(file).join.gsub("\r\n", "\n").split(";\n").each do |s|
          next if s == "\n"
          execute(s)
        end
      end
    end

end
