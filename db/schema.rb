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

ActiveRecord::Schema.define(:version => 20090529220256) do

  create_table "movie_items", :force => true do |t|
    t.integer  "last_week"
    t.integer  "this_week"
    t.integer  "weeks_released"
    t.float    "weekend_gross"
    t.float    "theater_average"
    t.integer  "movie_id"
    t.integer  "weekend_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "movie_items", ["movie_id", "weekend_id"], :name => "index_movie_items_on_movie_id_and_weekend_id", :unique => true

  create_table "movies", :force => true do |t|
    t.string   "title",                                 :null => false
    t.string   "rating"
    t.integer  "duration"
    t.boolean  "processed",          :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_file_name"
    t.string   "image_remote_url"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.date     "released_at"
    t.text     "synopsis"
    t.float    "gross"
    t.string   "distributor"
    t.text     "actors"
    t.string   "directors"
    t.string   "imdbid"
    t.string   "gid"
    t.integer  "tmeter"
    t.integer  "reviews_count",      :default => 0
    t.integer  "yid"
  end

  create_table "reviews", :force => true do |t|
    t.text     "comment"
    t.string   "author"
    t.string   "source"
    t.integer  "rating"
    t.date     "reviewed_on"
    t.integer  "movie_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reviews", ["author", "source", "movie_id"], :name => "index_reviews_on_author_and_source_and_movie_id", :unique => true

  create_table "shows", :force => true do |t|
    t.integer  "theater_id", :null => false
    t.integer  "movie_id",   :null => false
    t.text     "times"
    t.date     "shown_on"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shows", ["theater_id", "movie_id", "shown_on"], :name => "index_shows_on_theater_id_and_movie_id_and_date", :unique => true

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

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
    t.string   "gid"
    t.integer  "imdbid"
    t.string   "group"
  end

  add_index "theaters", ["gid"], :name => "index_theaters_on_gid"
  add_index "theaters", ["yid"], :name => "index_theaters_on_yid", :unique => true

  create_table "time_migrations", :force => true do |t|
    t.date     "migrated_at",  :null => false
    t.datetime "completed_at"
    t.string   "last_zip"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                              :null => false
    t.string   "crypted_password",                   :null => false
    t.string   "password_salt",                      :null => false
    t.string   "persistence_token",                  :null => false
    t.string   "single_access_token",                :null => false
    t.string   "perishable_token",                   :null => false
    t.integer  "login_count",         :default => 0, :null => false
    t.integer  "failed_login_count",  :default => 0, :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "weekends", :force => true do |t|
    t.date "weekend_at"
  end

end
