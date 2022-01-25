class SourceVideo < ActiveRecord::Base

  has_many :test_sequences
  has_many :thumbnails, dependent: :destroy
  has_many :experiment_source_video_assignments
  has_many :experiments, through: :experiment_source_video_assignments

  validates :src_id, :url, :name, presence: true
  validates :src_id, uniqueness: true

  translates :name, :description, :content_question

  before_validation :verify_url
  #after_create :attach_thumbnails

  def video_path
    [
      Settings.video.basepath,
      self.src_id,
      "#{self.src_id}.m3u8"
    ].join('/')
  end

  # Return a pretty readable duration
  def duration_hms
    Time.at(self.duration).utc.strftime("%H:%M:%S")
  end

  # create a URL for this video if it doesn't exist
  def verify_url
    if not File.exists? Rails.root.join(video_path)
      self.errors.add(:url, "File #{self.video_path} does not exist in the project!")
      return false
    end

    url = Settings.prefix + "/" + self.video_path
    url.slice!("/public/")

    self.url = url
  end

  # Import files in public/videos folder, including playlists and thumbnails.
  # Delete existing thumbnails.
  def attach_thumbnails!
    attach_thumbnails(force = true)
  end

  # Import files in public/videos folder, including playlists and thumbnails
  # Call with rake behavr:attach_thumbnails
  def attach_thumbnails(force = false)
    dir = File.dirname(Rails.root.join(self.video_path)) + "/thumbnails/"

    # skip if thumbnails exist
    unless force
      if self.thumbnails.any?
        puts "Skipping adding thumbnails for #{self.name}, already has some"
        return
      end
    end

    if not Dir.exists? dir
      puts "No thumbnail directory for #{self.name}, have you created #{dir}?"
      return
    end

    # collect all thumbnail filenames
    thumbs = []
    Dir.foreach(dir).each do |entry|
      next unless %w(.png .jpg .jpeg .bmp).include?(File.extname(entry))
      thumbs << entry
    end

    if thumbs.empty?
      puts "No thumbnails found for #{self.name}"
      return
    end

    self.thumbnails.destroy_all

    thumbs.sort.each do |thumb|
      t = self.thumbnails.new
      t.image = File.open(dir + '/' + thumb)
      t.save()
    end
  end

  # Assigns all videos to all existing experiments
  def self.assign_to_all_experiments
    SourceVideo.find_each do |video|
      Experiment.find_each do |exp|
        video.experiments << exp
        video.save
      end
    end
  end

end
