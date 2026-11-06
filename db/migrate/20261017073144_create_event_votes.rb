class CreateEventVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :event_votes do |t|
      t.references :event, null: false, foreign_key: true
      t.string :user_id, null: false
      t.string :vote_type, null: false

      t.timestamps

      t.index [  :event_id, :user_id ], unique: true
    end
  end
end
