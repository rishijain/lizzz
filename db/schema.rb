# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_17_112250) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.text "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.bigint "blog_site_id", null: false
    t.string "blog_url"
    t.string "source_type", default: "scraped"
    t.string "summary_status"
    t.index ["blog_site_id"], name: "index_articles_on_blog_site_id"
    t.index ["source_type"], name: "index_articles_on_source_type"
    t.index ["summary_status"], name: "index_articles_on_summary_status"
  end

  create_table "blog_sites", force: :cascade do |t|
    t.string "url"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "articles", "blog_sites"
end
