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

ActiveRecord::Schema.define(:version => 20090527192558) do

  create_table "movies", :force => true do |t|
    t.string   "title",                                 :null => false
    t.string   "rating"
    t.integer  "duration"
    t.integer  "mid",                                   :null => false
    t.boolean  "processed",          :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "synopsis"
    t.string   "image_file_name"
    t.string   "image_remote_url"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.date     "released_at"
    t.integer  "gross"
    t.string   "distributor"
    t.text     "actors"
    t.string   "directors"
    t.string   "imdbid"
    t.string   "gid"
    t.integer  "tmeter"
    t.integer  "reviews_count",      :default => 0
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
  end

  add_index "theaters", ["gid"], :name => "index_theaters_on_gid"
  add_index "theaters", ["yid"], :name => "index_theaters_on_yid", :unique => true

  create_table "time_migrations", :force => true do |t|
    t.date     "migrated_at",  :null => false
    t.datetime "completed_at"
    t.string   "last_zip"
  end

end
