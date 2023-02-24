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

ActiveRecord::Schema[7.0].define(version: 2023_02_24_174213) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "alert_messages", force: :cascade do |t|
    t.boolean "active", default: false
    t.string "message"
    t.string "level"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bulk_exports", force: :cascade do |t|
    t.bigint "created_by_id", null: false
    t.jsonb "search_params"
    t.string "process_errors", array: true
    t.integer "duration"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.datetime "generated_at"
    t.boolean "include_assets", default: false
    t.index ["created_by_id"], name: "index_bulk_exports_on_created_by_id"
  end

  create_table "bulk_imports", force: :cascade do |t|
    t.text "note"
    t.text "original_filename", null: false
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_bulk_imports_on_created_by_id"
  end

  create_table "imports", force: :cascade do |t|
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "process_errors", array: true
    t.jsonb "import_data"
    t.integer "duration"
    t.string "resource_identifier"
    t.bigint "bulk_import_id", null: false
    t.index ["bulk_import_id"], name: "index_imports_on_bulk_import_id"
  end

  create_table "orm_resources", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "internal_resource"
    t.integer "lock_version"
    t.index ["internal_resource"], name: "index_orm_resources_on_internal_resource"
    t.index ["metadata"], name: "index_orm_resources_on_metadata", using: :gin
    t.index ["metadata"], name: "index_orm_resources_on_metadata_jsonb_path_ops", opclass: :jsonb_path_ops, using: :gin
    t.index ["updated_at"], name: "index_orm_resources_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "remember_created_at"
    t.string "provider"
    t.string "uid"
    t.string "roles", default: [], array: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["roles"], name: "index_users_on_roles"
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bulk_exports", "users", column: "created_by_id"
  add_foreign_key "bulk_imports", "users", column: "created_by_id"
  add_foreign_key "imports", "bulk_imports"
end
