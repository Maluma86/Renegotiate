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

ActiveRecord::Schema[7.1].define(version: 2025_06_16_111335) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "discount_target_histories", force: :cascade do |t|
    t.bigint "renegotiation_id", null: false
    t.float "target_discount_percentage", null: false
    t.float "min_discount_percentage", null: false
    t.integer "set_by_user_id", null: false
    t.datetime "set_at", null: false
    t.integer "version_number", default: 1, null: false
    t.boolean "is_active", default: true, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["renegotiation_id", "is_active"], name: "index_discount_histories_on_renegotiation_and_active"
    t.index ["renegotiation_id", "version_number"], name: "index_discount_histories_on_renegotiation_and_version", unique: true
    t.index ["renegotiation_id"], name: "index_discount_target_histories_on_renegotiation_id"
    t.index ["set_by_user_id"], name: "index_discount_target_histories_on_set_by_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.text "description"
    t.float "current_price"
    t.float "last_month_volume"
    t.string "status"
    t.date "contract_end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "supplier_id", null: false
    t.bigint "procurement_id", null: false
    t.index ["procurement_id"], name: "index_products_on_procurement_id"
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
  end

  create_table "renegotiations", force: :cascade do |t|
    t.string "status"
    t.text "thread"
    t.string "tone"
    t.float "min_target"
    t.float "max_target"
    t.float "new_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "product_id", null: false
    t.bigint "buyer_id", null: false
    t.bigint "supplier_id", null: false
    t.float "current_target_discount_percentage"
    t.float "current_min_discount_percentage"
    t.boolean "discount_targets_locked", default: false, null: false
    t.integer "active_discount_target_version_id"
    t.index ["active_discount_target_version_id"], name: "index_renegotiations_on_active_discount_target_version_id"
    t.index ["buyer_id"], name: "index_renegotiations_on_buyer_id"
    t.index ["product_id", "buyer_id", "status"], name: "unique_ongoing_renegotiation_per_product_buyer", unique: true, where: "((status)::text = 'ongoing'::text)"
    t.index ["product_id"], name: "index_renegotiations_on_product_id"
    t.index ["supplier_id"], name: "index_renegotiations_on_supplier_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "company_name"
    t.string "role"
    t.string "contact"
    t.string "contact_email"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "discount_target_histories", "renegotiations"
  add_foreign_key "discount_target_histories", "users", column: "set_by_user_id"
  add_foreign_key "products", "users", column: "procurement_id"
  add_foreign_key "products", "users", column: "supplier_id"
  add_foreign_key "renegotiations", "discount_target_histories", column: "active_discount_target_version_id", on_delete: :nullify
  add_foreign_key "renegotiations", "products"
  add_foreign_key "renegotiations", "users", column: "buyer_id"
  add_foreign_key "renegotiations", "users", column: "supplier_id"
end
