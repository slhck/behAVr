# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150813082514) do

  create_table "behavior_events", force: :cascade do |t|
    t.integer  "sequence_result_id", limit: 4
    t.string   "type",               limit: 255
    t.text     "value",              limit: 65535
    t.datetime "client_time"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "behavior_events", ["sequence_result_id"], name: "index_behavior_events_on_sequence_result_id", using: :btree

  create_table "conditions", force: :cascade do |t|
    t.string   "cond_id",       limit: 255,   null: false
    t.text     "player_params", limit: 65535
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "experiment_condition_assignments", force: :cascade do |t|
    t.integer "experiment_id", limit: 4, null: false
    t.integer "condition_id",  limit: 4, null: false
  end

  add_index "experiment_condition_assignments", ["condition_id"], name: "index_experiment_condition_assignments_on_condition_id", using: :btree
  add_index "experiment_condition_assignments", ["experiment_id"], name: "index_experiment_condition_assignments_on_experiment_id", using: :btree

  create_table "experiment_progresses", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.integer  "experiment_id", limit: 4
    t.integer  "status",        limit: 4, default: 0
    t.datetime "joined"
    t.datetime "started"
    t.datetime "finished"
    t.datetime "completed"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "experiment_progresses", ["experiment_id"], name: "index_experiment_progresses_on_experiment_id", using: :btree
  add_index "experiment_progresses", ["user_id"], name: "index_experiment_progresses_on_user_id", using: :btree

  create_table "experiment_source_video_assignments", force: :cascade do |t|
    t.integer "experiment_id",   limit: 4, null: false
    t.integer "source_video_id", limit: 4, null: false
  end

  add_index "experiment_source_video_assignments", ["experiment_id"], name: "index_experiment_source_video_assignments_on_experiment_id", using: :btree
  add_index "experiment_source_video_assignments", ["source_video_id"], name: "index_experiment_source_video_assignments_on_source_video_id", using: :btree

  create_table "experiment_translations", force: :cascade do |t|
    t.integer  "experiment_id",     limit: 4,     null: false
    t.string   "locale",            limit: 255,   null: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.text     "description",       limit: 65535
    t.text     "introduction",      limit: 65535
    t.text     "main_instructions", limit: 65535
    t.text     "outro",             limit: 65535
  end

  add_index "experiment_translations", ["experiment_id"], name: "index_experiment_translations_on_experiment_id", using: :btree
  add_index "experiment_translations", ["locale"], name: "index_experiment_translations_on_locale", using: :btree

# Could not dump table "experiments" because of following FrozenError
#   can't modify frozen String: "false"

  create_table "rating_prototype_translations", force: :cascade do |t|
    t.integer  "rating_prototype_id", limit: 4,     null: false
    t.string   "locale",              limit: 255,   null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.text     "question",            limit: 65535
  end

  add_index "rating_prototype_translations", ["locale"], name: "index_rating_prototype_translations_on_locale", using: :btree
  add_index "rating_prototype_translations", ["rating_prototype_id"], name: "index_rating_prototype_translations_on_rating_prototype_id", using: :btree

  create_table "rating_prototypes", force: :cascade do |t|
    t.text     "question",      limit: 65535
    t.string   "answer_type",   limit: 255
    t.boolean  "required"
    t.integer  "order",         limit: 4
    t.integer  "experiment_id", limit: 4
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "rating_prototypes", ["experiment_id"], name: "index_rating_prototypes_on_experiment_id", using: :btree

  create_table "ratings", force: :cascade do |t|
    t.integer  "sequence_result_id",  limit: 4
    t.integer  "rating_prototype_id", limit: 4
    t.text     "answer",              limit: 65535
    t.datetime "client_time"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "ratings", ["rating_prototype_id"], name: "index_ratings_on_rating_prototype_id", using: :btree
  add_index "ratings", ["sequence_result_id"], name: "index_ratings_on_sequence_result_id", using: :btree

  create_table "sequence_results", force: :cascade do |t|
    t.integer  "experiment_progress_id", limit: 4
    t.integer  "test_sequence_id",       limit: 4
    t.integer  "user_id",                limit: 4
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "sequence_results", ["experiment_progress_id"], name: "index_sequence_results_on_experiment_progress_id", using: :btree
  add_index "sequence_results", ["test_sequence_id"], name: "index_sequence_results_on_test_sequence_id", using: :btree
  add_index "sequence_results", ["user_id"], name: "index_sequence_results_on_user_id", using: :btree

  create_table "source_video_translations", force: :cascade do |t|
    t.integer  "source_video_id",  limit: 4,     null: false
    t.string   "locale",           limit: 255,   null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "name",             limit: 255
    t.text     "description",      limit: 65535
    t.text     "content_question", limit: 65535
  end

  add_index "source_video_translations", ["locale"], name: "index_source_video_translations_on_locale", using: :btree
  add_index "source_video_translations", ["source_video_id"], name: "index_source_video_translations_on_source_video_id", using: :btree

  create_table "source_videos", force: :cascade do |t|
    t.string   "src_id",           limit: 255,   null: false
    t.string   "url",              limit: 255
    t.string   "name",             limit: 255
    t.integer  "duration",         limit: 4
    t.text     "description",      limit: 65535
    t.text     "content_question", limit: 65535
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "test_sequences", force: :cascade do |t|
    t.string   "sequence_id",     limit: 255, null: false
    t.integer  "condition_id",    limit: 4
    t.integer  "source_video_id", limit: 4
    t.integer  "experiment_id",   limit: 4
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "test_sequences", ["condition_id"], name: "index_test_sequences_on_condition_id", using: :btree
  add_index "test_sequences", ["experiment_id"], name: "index_test_sequences_on_experiment_id", using: :btree
  add_index "test_sequences", ["source_video_id"], name: "index_test_sequences_on_source_video_id", using: :btree

  create_table "thumbnails", force: :cascade do |t|
    t.integer  "source_video_id",    limit: 4
    t.integer  "order",              limit: 4,   default: 0
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "image_file_name",    limit: 255
    t.string   "image_content_type", limit: 255
    t.integer  "image_file_size",    limit: 4
    t.datetime "image_updated_at"
  end

  add_index "thumbnails", ["source_video_id"], name: "index_thumbnails_on_source_video_id", using: :btree

  create_table "user_test_sequence_assignments", force: :cascade do |t|
    t.integer "user_id",          limit: 4, null: false
    t.integer "test_sequence_id", limit: 4, null: false
  end

  add_index "user_test_sequence_assignments", ["test_sequence_id"], name: "index_user_test_sequence_assignments_on_test_sequence_id", using: :btree
  add_index "user_test_sequence_assignments", ["user_id"], name: "index_user_test_sequence_assignments_on_user_id", using: :btree

# Could not dump table "users" because of following FrozenError
#   can't modify frozen String: "false"

  add_foreign_key "behavior_events", "sequence_results"
  add_foreign_key "experiment_progresses", "experiments"
  add_foreign_key "experiment_progresses", "users"
  add_foreign_key "rating_prototypes", "experiments"
  add_foreign_key "ratings", "rating_prototypes"
  add_foreign_key "ratings", "sequence_results"
  add_foreign_key "sequence_results", "experiment_progresses"
  add_foreign_key "sequence_results", "test_sequences"
  add_foreign_key "sequence_results", "users"
  add_foreign_key "test_sequences", "conditions"
  add_foreign_key "test_sequences", "experiments"
  add_foreign_key "test_sequences", "source_videos"
  add_foreign_key "thumbnails", "source_videos"
end
