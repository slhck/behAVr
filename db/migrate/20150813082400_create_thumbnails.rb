class CreateThumbnails < ActiveRecord::Migration
  def change
    create_table :thumbnails do |t|
      t.references :source_video, index: true, foreign_key: true
      t.integer :order, default: 0

      t.timestamps null: false
    end
  end
end
