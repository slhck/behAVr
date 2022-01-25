class CreateSourceVideos < ActiveRecord::Migration
  def up
    create_table :source_videos do |t|
      t.string :src_id,     null: false
      t.string :url
      t.string :name
      t.integer :duration
      t.text :description
      t.text :content_question

      t.timestamps null: false
    end
    SourceVideo.create_translation_table! name: :string, description: :text, content_question: :text

    create_table :experiment_source_video_assignments do |t|
      t.references :experiment, index: true, null: false
      t.references :source_video, index: true, null: false
    end
  end

  def down
    drop_table :source_videos
    drop_table :experiment_source_video_assignments
    SourceVideo.drop_translation_table
  end
end
