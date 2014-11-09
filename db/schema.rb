# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141109135956) do

  create_table "messages", force: true do |t|
    t.string   "name",                       null: false
    t.string   "email",                      null: false
    t.text     "body"
    t.boolean  "read",       default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", force: true do |t|
    t.string   "title",      null: false
    t.string   "slug",       null: false
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pages", ["slug"], name: "index_pages_on_slug", unique: true

  create_table "posts", force: true do |t|
    t.string   "title",        null: false
    t.string   "slug",         null: false
    t.datetime "published_on"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "posts", ["slug"], name: "index_posts_on_slug", unique: true

  create_table "taggings", force: true do |t|
    t.integer "post_id"
    t.integer "tag_id"
  end

  create_table "tags", force: true do |t|
    t.string "name", null: false
    t.string "slug", null: false
  end

  add_index "tags", ["slug"], name: "index_tags_on_slug", unique: true

end
