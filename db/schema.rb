# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090522230609) do

  create_table "movies", :force => true do |t|
    t.string   "title",                         :null => false
    t.string   "rating"
    t.integer  "duration"
    t.integer  "mid",                           :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "processed",  :default => false
  end

  create_table "shows", :force => true do |t|
    t.integer  "theater_id", :null => false
    t.integer  "movie_id",   :null => false
    t.text     "times"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shows", ["theater_id", "movie_id", "date"], :name => "index_shows_on_theater_id_and_movie_id_and_date", :unique => true

  create_table "theaters", :force => true do |t|
    t.string   "name"
    t.string   "street"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone"
    t.decimal  "latitude",   :precision => 15, :scale => 10
    t.decimal  "longitude",  :precision => 15, :scale => 10
    t.integer  "yid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "theaters", ["yid"], :name => "index_theaters_on_yid", :unique => true

  create_table "time_migrations", :force => true do |t|
    t.date     "date",         :null => false
    t.datetime "completed_at"
    t.string   "last_zip"
  end

end
