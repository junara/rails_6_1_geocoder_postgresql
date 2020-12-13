# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_13_035657) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "crimes", force: :cascade do |t|
    t.bigint "incident_id"
    t.bigint "offence_id"
    t.integer "offence_code"
    t.integer "offence_code_extension"
    t.string "offence_type_id"
    t.string "offence_category_id"
    t.date "first_occurrence_date"
    t.string "incident_address"
    t.decimal "longitude", precision: 11, scale: 8, null: false
    t.decimal "latitude", precision: 11, scale: 8, null: false
    t.integer "district_id"
    t.boolean "is_crime"
    t.boolean "is_traffic"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.geography "location", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.index ["location"], name: "index_crimes_on_location", using: :gist
    t.index ["longitude", "latitude"], name: "index_crimes_on_longitude_and_latitude"
  end

end
