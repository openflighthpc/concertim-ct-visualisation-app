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

ActiveRecord::Schema[7.0].define(version: 2023_03_28_104555) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  connection.execute "CREATE SCHEMA IF NOT EXISTS public"
  connection.execute "CREATE SCHEMA IF NOT EXISTS uma"
  connection.execute "CREATE SCHEMA IF NOT EXISTS meca"
  connection.execute "CREATE SCHEMA IF NOT EXISTS ivy"

  connection.schema_search_path = "public,uma,meca,ivy"

  create_table "ivy.base_chassis", id: :bigint, default: -> { "nextval('base_chassis_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "name", limit: 255, default: "", null: false
    t.integer "u_height", default: 1, null: false
    t.integer "u_depth", default: 2, null: false
    t.string "facing", default: "f", null: false
    t.integer "rack_start_u", null: false
    t.integer "rack_end_u", null: false
    t.string "slot_population_order", limit: 8, default: "lr-bt", null: false
    t.string "type", limit: 255, null: false
    t.integer "modified_timestamp", default: 0, null: false
    t.boolean "show_in_dcrv", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "rack_id", null: false
    t.bigint "template_id", null: false
    t.index ["rack_id"], name: "index_base_chassis_on_rack_id"
    t.index ["template_id"], name: "index_base_chassis_on_template_id"
  end

  create_table "ivy.chassis_rows", id: :bigint, default: -> { "nextval('chassis_rows_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "row_number", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "base_chassis_id", null: false
    t.index ["base_chassis_id"], name: "index_chassis_rows_on_base_chassis_id"
  end

  create_table "ivy.data_source_maps", id: :bigint, default: -> { "nextval('data_source_maps_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "map_to_grid", limit: 56, null: false
    t.string "map_to_cluster", limit: 56, null: false
    t.string "map_to_host", limit: 150, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "device_id", null: false
    t.index ["device_id"], name: "index_data_source_maps_on_device_id"
  end

  create_table "ivy.devices", id: :bigint, default: -> { "nextval('devices_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "description", limit: 255
    t.string "type", limit: 255, default: "Server", null: false
    t.boolean "tagged", default: false, null: false
    t.boolean "hidden", default: false, null: false
    t.integer "modified_timestamp", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "slot_id"
    t.bigint "base_chassis_id"
    t.index ["base_chassis_id"], name: "index_devices_on_base_chassis_id"
    t.index ["slot_id"], name: "index_devices_on_slot_id"
  end

  create_table "ivy.racks", id: :bigint, default: -> { "nextval('racks_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.integer "u_height", default: 42, null: false
    t.integer "u_depth", default: 2, null: false
    t.integer "modified_timestamp", default: 0, null: false
    t.integer "tagged_device_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "template_id", null: false
    t.index ["template_id"], name: "index_racks_on_template_id"
  end

  create_table "ivy.slots", id: :bigint, default: -> { "nextval('slots_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "chassis_row_location", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "chassis_row_id", null: false
    t.index ["chassis_row_id"], name: "index_slots_on_chassis_row_id"
  end

  create_table "ivy.templates", id: :bigint, default: -> { "nextval('templates_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "template_name", limit: 255, default: "", null: false
    t.integer "height", null: false
    t.integer "depth", null: false
    t.integer "version", default: 1, null: false
    t.string "chassis_type", limit: 255, null: false
    t.integer "template_id", null: false
    t.integer "rackable", default: 1, null: false
    t.boolean "simple", default: true, null: false
    t.string "description", limit: 255
    t.jsonb "images"
    t.integer "rows", default: 1, null: false
    t.integer "columns", default: 1, null: false
    t.integer "padding_left", default: 0, null: false
    t.integer "padding_bottom", default: 0, null: false
    t.integer "padding_right", default: 0, null: false
    t.integer "padding_top", default: 0, null: false
    t.string "name", limit: 255
    t.string "manufacturer", limit: 255
    t.string "model", limit: 255
    t.string "product_url", limit: 255
    t.string "rack_repeat_ratio", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meca.rackview_presets", id: :bigint, default: -> { "nextval('rackview_presets_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.boolean "default", default: false, null: false
    t.jsonb "values"
    t.integer "user_id"
    t.boolean "global", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "uma.users", id: :bigint, default: -> { "nextval('users_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "login", limit: 80, null: false
    t.string "firstname", limit: 56, null: false
    t.string "surname", limit: 56, null: false
    t.text "email", default: "", null: false
    t.string "encrypted_password", limit: 128, default: "", null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.integer "sign_in_count", default: 0, null: false
    t.text "authentication_token"
    t.datetime "remember_created_at"
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at"
    t.boolean "root", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_uma.users_on_email", unique: true
    t.index ["login"], name: "index_uma.users_on_login", unique: true
  end

  add_foreign_key "ivy.base_chassis", "racks", on_update: :cascade, on_delete: :restrict
  add_foreign_key "ivy.base_chassis", "templates", on_update: :cascade, on_delete: :restrict
  add_foreign_key "ivy.chassis_rows", "base_chassis", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ivy.data_source_maps", "devices", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ivy.devices", "base_chassis", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ivy.devices", "slots", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ivy.racks", "templates", on_update: :cascade, on_delete: :restrict
  add_foreign_key "ivy.slots", "chassis_rows", on_update: :cascade, on_delete: :cascade
end
