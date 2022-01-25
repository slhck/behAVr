class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.references :sequence_result, index: true, foreign_key: true
      t.references :rating_prototype, index: true, foreign_key: true
      t.text :answer
      t.timestamp :client_time

      t.timestamps null: false
    end
  end
end
