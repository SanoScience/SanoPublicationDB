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

ActiveRecord::Schema[8.0].define(version: 2025_02_07_155143) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "identifiers", force: :cascade do |t|
    t.bigint "publication_id"
    t.string "type"
    t.string "value"
    t.index ["publication_id"], name: "index_identifiers_on_publication_id"
  end

  create_table "publications", force: :cascade do |t|
    t.string "title", null: false
    t.integer "type", null: false
    t.integer "status", null: false
    t.string "author_list", null: false
    t.integer "journal_issue_id"
    t.integer "conference_id"
    t.date "publication_date"
    t.string "link", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "repository_links", force: :cascade do |t|
    t.bigint "publication_id"
    t.string "repository"
    t.string "value"
    t.index ["publication_id"], name: "index_repository_links_on_publication_id"
  end

  create_table "research_group_publications", force: :cascade do |t|
    t.bigint "publication_id"
    t.string "research_group"
    t.boolean "is_primary"
    t.index ["publication_id"], name: "index_research_group_publications_on_publication_id"
  end
end
