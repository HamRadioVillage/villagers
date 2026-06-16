class CreateConferencePrograms < ActiveRecord::Migration[8.1]
  def change
    create_table :conference_programs do |t|
      t.references :conference, null: false, foreign_key: true
      t.references :program, null: false, foreign_key: true
      t.text :public_description
      # `json` (not `jsonb`) for cross-database support; MySQL/MariaDB don't have
      # jsonb. No column default: MySQL/MariaDB can't default JSON columns, so the
      # default empty hash is provided by ConferenceProgram#day_schedules instead.
      t.json :day_schedules

      t.timestamps
    end

    add_index :conference_programs, [ :conference_id, :program_id ], unique: true
  end
end
