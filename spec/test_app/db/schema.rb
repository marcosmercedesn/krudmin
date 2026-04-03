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

ActiveRecord::Schema[8.1].define(version: 2026_04_02_234043) do
  create_table "car_brands", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "description", null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "car_insurances", force: :cascade do |t|
    t.integer "car_id"
    t.date "date"
    t.string "license_number"
    t.index ["car_id"], name: "index_car_insurances_on_car_id"
  end

  create_table "car_owners", force: :cascade do |t|
    t.integer "license_number"
    t.string "name"
  end

  create_table "cars", force: :cascade do |t|
    t.boolean "active"
    t.integer "car_brand_id"
    t.integer "car_owner_id"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.string "model"
    t.date "release_date"
    t.integer "status", default: 0, null: false
    t.integer "transmission"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "year"
    t.index ["car_brand_id"], name: "index_cars_on_car_brand_id"
    t.index ["car_owner_id"], name: "index_cars_on_car_owner_id"
    t.index ["status"], name: "index_cars_on_status"
  end

  create_table "krudmin_audit_entries", force: :cascade do |t|
    t.string "action", null: false
    t.integer "auditable_id", null: false
    t.string "auditable_type", null: false
    t.text "changes_json"
    t.datetime "created_at", null: false
    t.text "metadata"
    t.integer "user_id"
    t.string "user_type"
    t.index ["action"], name: "index_krudmin_audit_entries_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_krudmin_audit_on_auditable"
    t.index ["created_at"], name: "index_krudmin_audit_entries_on_created_at"
    t.index ["user_type", "user_id"], name: "index_krudmin_audit_on_user"
  end

  create_table "passengers", force: :cascade do |t|
    t.integer "age"
    t.integer "car_id"
    t.string "email"
    t.integer "gender"
    t.string "name"
    t.index ["car_id"], name: "index_passengers_on_car_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip"
    t.string "name", null: false
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end
end
