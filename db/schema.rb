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

ActiveRecord::Schema[8.0].define(version: 2025_06_18_091613) do
  create_table "events", force: :cascade do |t|
    t.string "name"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plays", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "video_url"
    t.integer "user_id", null: false
    t.string "status", default: "approved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "event_id", default: 1, null: false
    t.integer "elo", default: 1000, null: false
    t.index ["created_at"], name: "index_plays_on_created_at"
    t.index ["event_id"], name: "index_plays_on_event_id"
    t.index ["status"], name: "index_plays_on_status"
    t.index ["user_id"], name: "index_plays_on_user_id"
  end

  create_table "race_deadlines", force: :cascade do |t|
    t.string "race_type", null: false
    t.date "due_date", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "start_date"
    t.index ["race_type", "active"], name: "index_race_deadlines_on_race_type_and_active"
  end

  create_table "runs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.date "date"
    t.integer "time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "race_type", default: "5k", null: false
    t.string "source"
    t.float "strava_distance"
    t.index ["user_id"], name: "index_runs_on_user_id"
  end

  create_table "strava_tokens", force: :cascade do |t|
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.integer "expires_in"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.string "strava_athlete_id"
    t.string "firstname"
    t.string "lastname"
    t.string "strava_username"
    t.string "email"
    t.datetime "last_login_at"
    t.integer "login_count", default: 0, null: false
    t.string "user_type", default: "player", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["strava_athlete_id"], name: "index_users_on_strava_athlete_id", unique: true
    t.index ["user_type"], name: "index_users_on_user_type"
  end

  add_foreign_key "plays", "events"
  add_foreign_key "plays", "users"
  add_foreign_key "runs", "users"
end
