class CreateSequenceResults < ActiveRecord::Migration
  def change
    create_table :sequence_results do |t|
      t.references :experiment_progress, index: true, foreign_key: true
      t.references :test_sequence, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
