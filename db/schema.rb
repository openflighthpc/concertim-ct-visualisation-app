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

ActiveRecord::Schema[7.0].define(version: 2023_09_05_094853) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "base_chassis", force: :cascade do |t|
    t.string "name", limit: 255, default: "", null: false
    t.integer "modified_timestamp", default: 0, null: false
    t.boolean "show_in_dcrv", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "template_id", null: false
    t.bigint "location_id", null: false
    t.index ["location_id"], name: "index_base_chassis_on_location_id"
    t.index ["template_id"], name: "index_base_chassis_on_template_id"
  end

  create_table "cloud_service_configs", force: :cascade do |t|
    t.string "admin_user_id", limit: 255, null: false
    t.string "admin_project_id", limit: 255, null: false
    t.integer "user_handler_port", default: 42356, null: false
    t.integer "cluster_builder_port", default: 42378, null: false
    t.string "host_url", limit: 255, null: false
    t.string "internal_auth_url", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "admin_foreign_password"
  end

  create_table "cluster_types", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "description", limit: 1024, null: false
    t.string "foreign_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "fields", default: {}, null: false
    t.datetime "version"
  end

  create_table "data_source_maps", force: :cascade do |t|
    t.string "map_to_grid", limit: 56, null: false
    t.string "map_to_cluster", limit: 56, null: false
    t.string "map_to_host", limit: 150, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "device_id", null: false
    t.index ["device_id"], name: "index_data_source_maps_on_device_id"
  end

  create_table "devices", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "description", limit: 255
    t.boolean "hidden", default: false, null: false
    t.integer "modified_timestamp", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "base_chassis_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "status", null: false
    t.decimal "cost", default: "0.0", null: false
    t.string "public_ips"
    t.string "private_ips"
    t.string "ssh_key"
    t.string "login_user"
    t.jsonb "volume_details", default: {}, null: false
    t.index ["base_chassis_id"], name: "index_devices_on_base_chassis_id"
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

  create_table "locations", force: :cascade do |t|
    t.integer "u_depth", default: 2, null: false
    t.integer "u_height", default: 1, null: false
    t.integer "start_u", null: false
    t.integer "end_u", null: false
    t.string "facing", default: "f", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "rack_id", null: false
    t.index ["rack_id"], name: "index_locations_on_rack_id"
  end

  create_table "racks", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.integer "u_height", default: 42, null: false
    t.integer "u_depth", default: 2, null: false
    t.integer "modified_timestamp", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "template_id", null: false
    t.bigint "user_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "status", null: false
    t.decimal "cost", default: "0.0", null: false
    t.string "creation_output"
    t.jsonb "network_details", default: {}, null: false
    t.index ["template_id"], name: "index_racks_on_template_id"
    t.index ["user_id"], name: "index_racks_on_user_id"
  end

  create_table "rackview_presets", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.boolean "default", default: false, null: false
    t.jsonb "values"
    t.integer "user_id"
    t.boolean "global", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "templates", force: :cascade do |t|
    t.string "name", limit: 255, default: "", null: false
    t.integer "height", null: false
    t.integer "depth", null: false
    t.integer "version", default: 1, null: false
    t.string "template_type", limit: 255, null: false
    t.integer "rackable", default: 1, null: false
    t.boolean "simple", default: true, null: false
    t.string "description", limit: 255
    t.jsonb "images", default: {}, null: false
    t.integer "rows"
    t.integer "columns"
    t.integer "padding_left", default: 0, null: false
    t.integer "padding_bottom", default: 0, null: false
    t.integer "padding_right", default: 0, null: false
    t.integer "padding_top", default: 0, null: false
    t.string "model", limit: 255
    t.string "rack_repeat_ratio", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "foreign_id"
    t.integer "vcpus"
    t.integer "ram"
    t.integer "disk"
  end

  create_table "users", force: :cascade do |t|
    t.string "login", limit: 80, null: false
    t.string "name", limit: 56, null: false
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
    t.string "project_id", limit: 255
    t.uuid "cloud_user_id"
    t.decimal "cost", default: "0.0", null: false
    t.date "billing_period_start"
    t.date "billing_period_end"
    t.string "foreign_password"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["login"], name: "index_users_on_login", unique: true
    t.index ["project_id"], name: "index_users_on_project_id", unique: true, where: "(NOT NULL::boolean)"
  end

  add_foreign_key "base_chassis", "locations", on_update: :cascade, on_delete: :restrict
  add_foreign_key "base_chassis", "templates", on_update: :cascade, on_delete: :restrict
  add_foreign_key "data_source_maps", "devices", on_update: :cascade, on_delete: :cascade
  add_foreign_key "devices", "base_chassis", on_update: :cascade, on_delete: :cascade
  add_foreign_key "locations", "racks", on_update: :cascade, on_delete: :restrict
  add_foreign_key "racks", "templates", on_update: :cascade, on_delete: :restrict
  add_foreign_key "racks", "users", on_update: :cascade, on_delete: :restrict
end