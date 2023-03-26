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

ActiveRecord::Schema.define(version: 20230322141800) do

  create_table "attendances", force: :cascade do |t|
    t.date "worked_on"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "note"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "overwork_finish_time"
    t.string "overwork_business_process_content"
    t.boolean "overwork_next_day_checkmark", default: false
    t.boolean "overwork_change_checkmark", default: false
    t.string "overwork_stamp_select_superior"
    t.string "overwork_stamp_confirm_step"
    t.datetime "before_change_started_at"
    t.datetime "before_change_finished_at"
    t.datetime "after_change_started_at"
    t.datetime "after_change_finished_at"
    t.boolean "change_attendance_next_day_checkmark", default: false
    t.boolean "change_attendance_change_checkmark", default: false
    t.string "change_attendance_stamp_select_superior"
    t.string "change_attendance_stamp_confirm_step"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "bases", force: :cascade do |t|
    t.integer "base_number"
    t.string "base_name"
    t.string "attendance_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "affiliation"
    t.datetime "basic_time", default: "2023-03-26 23:00:00"
    t.datetime "work_time", default: "2023-03-26 22:30:00"
    t.integer "employee_number"
    t.string "uid"
    t.datetime "basic_work_time", default: "2023-03-26 23:00:00"
    t.datetime "designated_work_start_time", default: "2023-03-27 00:00:00"
    t.datetime "designated_work_end_time", default: "2023-03-27 09:00:00"
    t.boolean "superior", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
