class CreateWeekends < ActiveRecord::Migration
  def self.up
    create_table :weekends do |t|
      t.date :weekend_at
    end
  end

  def self.down
    drop_table :weekends
  end
end
