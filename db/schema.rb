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

ActiveRecord::Schema[8.0].define(version: 2025_08_18_135229) do
  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.integer "resource_id"
    t.string "author_type"
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "episodes", force: :cascade do |t|
    t.integer "series_id", null: false
    t.string "title", null: false
    t.integer "season_number", null: false
    t.integer "episode_number", null: false
    t.date "air_date", null: false
    t.boolean "is_season_finale", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "air_time"
    t.integer "runtime_minutes"
    t.string "original_timezone"
    t.datetime "air_datetime_utc"
    t.text "overview"
    t.index ["air_date"], name: "index_episodes_on_air_date"
    t.index ["air_datetime_utc"], name: "index_episodes_on_air_datetime_utc"
    t.index ["series_id", "season_number", "episode_number"], name: "idx_on_series_id_season_number_episode_number_ac8d2e3ce3", unique: true
    t.index ["series_id"], name: "index_episodes_on_series_id"
  end

  create_table "series", force: :cascade do |t|
    t.integer "tvdb_id", null: false
    t.string "name", null: false
    t.string "imdb_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_synced_at"
    t.index ["last_synced_at"], name: "index_series_on_last_synced_at"
    t.index ["tvdb_id"], name: "index_series_on_tvdb_id", unique: true
  end

  create_table "user_series", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "series_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["series_id"], name: "index_user_series_on_series_id"
    t.index ["user_id", "series_id"], name: "index_user_series_on_user_id_and_series_id", unique: true
    t.index ["user_id"], name: "index_user_series_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "pin", null: false
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["pin"], name: "index_users_on_pin", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  add_foreign_key "episodes", "series"
  add_foreign_key "user_series", "series"
  add_foreign_key "user_series", "users"
end
