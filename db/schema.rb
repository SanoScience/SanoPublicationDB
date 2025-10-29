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

ActiveRecord::Schema[8.0].define(version: 2025_10_29_124019) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "unaccent"

  create_table "conferences", force: :cascade do |t|
    t.string "name", null: false
    t.string "core"
    t.date "start_date"
    t.date "end_date"
  end

  create_table "identifiers", force: :cascade do |t|
    t.bigint "publication_id", null: false
    t.string "category", null: false
    t.string "value", null: false
    t.index ["publication_id"], name: "index_identifiers_on_publication_id"
  end

  create_table "journal_issues", force: :cascade do |t|
    t.string "title", null: false
    t.string "journal_num"
    t.string "publisher"
    t.integer "volume"
    t.float "impact_factor"
  end

  create_table "kpi_reporting_extensions", force: :cascade do |t|
    t.bigint "publication_id", null: false
    t.integer "teaming_reporting_period"
    t.string "invoice_number"
    t.boolean "pbn"
    t.boolean "jcr"
    t.boolean "is_added_ft_portal"
    t.boolean "is_checked"
    t.boolean "is_new_method_technique"
    t.boolean "is_methodology_application"
    t.boolean "is_polish_med_researcher_involved"
    t.integer "subsidy_points"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_peer_reviewed"
    t.boolean "is_co_publication_with_partners"
    t.index ["publication_id"], name: "index_kpi_reporting_extensions_on_publication_id"
  end

  create_table "open_access_extensions", force: :cascade do |t|
    t.bigint "publication_id", null: false
    t.decimal "gold_oa_charges"
    t.string "gold_oa_funding_source"
    t.integer "category", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publication_id"], name: "index_open_access_extensions_on_publication_id"
  end

  create_table "publications", force: :cascade do |t|
    t.string "title", null: false
    t.integer "category", null: false
    t.integer "status", null: false
    t.string "author_list", null: false
    t.integer "publication_year"
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "journal_issue_id"
    t.bigint "conference_id"
    t.bigint "owner_id"
    t.index ["conference_id"], name: "index_publications_on_conference_id"
    t.index ["journal_issue_id"], name: "index_publications_on_journal_issue_id"
    t.index ["owner_id"], name: "index_publications_on_owner_id"
  end

  create_table "repository_links", force: :cascade do |t|
    t.bigint "publication_id", null: false
    t.string "repository", null: false
    t.string "value", null: false
    t.index ["publication_id"], name: "index_repository_links_on_publication_id"
  end

  create_table "research_group_publications", force: :cascade do |t|
    t.bigint "publication_id", null: false
    t.boolean "is_primary", null: false
    t.bigint "research_group_id"
    t.index ["publication_id"], name: "index_research_group_publications_on_publication_id"
    t.index ["research_group_id"], name: "index_research_group_publications_on_research_group_id"
  end

  create_table "research_groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_research_groups_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "role", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "identifiers", "publications", on_delete: :cascade
  add_foreign_key "kpi_reporting_extensions", "publications", on_delete: :cascade
  add_foreign_key "open_access_extensions", "publications", on_delete: :cascade
  add_foreign_key "publications", "conferences", on_delete: :nullify
  add_foreign_key "publications", "journal_issues", on_delete: :nullify
  add_foreign_key "publications", "users", column: "owner_id", on_delete: :nullify
  add_foreign_key "repository_links", "publications", on_delete: :cascade
  add_foreign_key "research_group_publications", "publications", on_delete: :cascade
  add_foreign_key "research_group_publications", "research_groups"
end
