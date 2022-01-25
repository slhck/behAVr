class CreateTestSequences < ActiveRecord::Migration
  def change
    create_table :test_sequences do |t|
      t.string :sequence_id, null: false
      t.references :condition, index: true, foreign_key: true
      t.references :source_video, index: true, foreign_key: true
      t.references :experiment, index: true, foreign_key: true

      t.timestamps null: false
    end

    create_table :user_test_sequence_assignments do |t|
      t.references :user, index: true, null: false
      t.references :test_sequence, index: true, null: false
    end
  end
end
