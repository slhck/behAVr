class CreateExperiments < ActiveRecord::Migration
  def up
    create_table :experiments do |t|
      t.string :name
      t.text :description
      t.text :introduction
      t.text :main_instructions
      t.text :outro
      t.boolean :active, default: false
      t.boolean :require_access_key, default: false
      t.boolean :require_finish_key, default: false
      t.string :access_key
      t.string :finish_key
      t.string :pre_questionnaire_url
      t.string :post_questionnaire_url
      t.integer :test_sequence_mapping, default: 0
      t.string :reference_condition
      t.string :finish_condition

      t.timestamps null: false
    end
    Experiment.create_translation_table! description: :text,
                                         introduction: :text,
                                         main_instructions: :text,
                                         outro: :text
  end

  def down
    drop_table :experiments
    Experiment.drop_translation_table
  end
end
