class CreateExperimentProgresses < ActiveRecord::Migration
  def change
    create_table :experiment_progresses do |t|
      t.references :user, index: true, foreign_key: true
      t.references :experiment, index: true, foreign_key: true

      t.integer :status, default: 0
      t.timestamp :joined
      t.timestamp :started
      t.timestamp :finished
      t.timestamp :completed

      t.timestamps null: false
    end
  end
end
