class CreateBehaviorEvents < ActiveRecord::Migration
  def change
    create_table :behavior_events do |t|
      t.references :sequence_result, index: true, foreign_key: true

      t.string :type
      t.text :value
      t.timestamp :client_time

      t.timestamps null: false
    end
  end
end
