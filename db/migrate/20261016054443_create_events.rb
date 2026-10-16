class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.integer :external_id
      t.string :title
      t.text :description
      t.string :image_link
      t.datetime :startdate
      t.datetime :enddate
      t.string :url
      t.string :location
      t.string :organiser_name
      t.boolean :availability
      t.string :minimum_price
      t.jsonb :categorization
      t.jsonb :billetto_data

      t.timestamps
    end
  end
end
