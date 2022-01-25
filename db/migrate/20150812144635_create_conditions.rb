class CreateConditions < ActiveRecord::Migration
  def change
    create_table :conditions do |t|
      t.string :cond_id, null: false
      t.text :player_params

      t.timestamps null: false
    end

    create_table :experiment_condition_assignments do |t|
      t.references :experiment, index: true, null: false
      t.references :condition, index: true, null: false
    end
  end
end
