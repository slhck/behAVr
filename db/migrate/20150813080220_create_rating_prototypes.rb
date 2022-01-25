class CreateRatingPrototypes < ActiveRecord::Migration
  def up
    create_table :rating_prototypes do |t|
      t.text :question
      t.string :answer_type
      t.boolean :required
      t.integer :order
      t.references :experiment, index: true, foreign_key: true
      t.timestamps null: false
    end

    RatingPrototype.create_translation_table! question: :text
  end

  def down
    drop_table :rating_prototypes
    RatingPrototype.drop_translation_table
  end
end
