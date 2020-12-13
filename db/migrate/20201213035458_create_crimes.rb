class CreateCrimes < ActiveRecord::Migration[6.0]
  def change
    create_table :crimes do |t|
      t.bigint :incident_id
      t.bigint :offence_id
      t.integer :offence_code
      t.integer :offence_code_extension
      t.string :offence_type_id
      t.string :offence_category_id
      t.date :first_occurrence_date
      t.string :incident_address
      t.decimal :longitude, precision: 11, scale: 8, null: false
      t.decimal :latitude, precision: 11, scale: 8, null: false
      t.integer :district_id
      t.boolean :is_crime
      t.boolean :is_traffic
      t.timestamps
    end
    add_index :crimes, [:longitude, :latitude]
  end
end
