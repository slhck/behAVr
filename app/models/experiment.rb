class Experiment < ActiveRecord::Base

  has_many :experiment_progresses, dependent: :destroy
  has_many :users, through: :experiment_progresses
  has_many :test_sequences, dependent: :destroy
  has_many :experiment_source_video_assignments, dependent: :destroy
  has_many :experiment_condition_assignments, dependent: :destroy
  has_many :source_videos, through: :experiment_source_video_assignments, dependent: :destroy
  has_many :conditions, through: :experiment_condition_assignments, dependent: :destroy
  has_many :rating_prototypes, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  after_create :create_progress_stubs

  scope :active, -> { where(active: true) }

  translates :description, :introduction, :main_instructions, :outro

  # specify how conditions shall be mapped to the SRCs as test sequences
  enum test_sequence_mapping: [
    :manual,  # Conditions are manually mapped to SRCs to generate test sequences.
              # In the experiment configuration, use a list of Hashes, specifying:
              #
              # - sequence_id:
              #     src_id: <srcId>
              #     condition_id: <conditionId>
              #
              # et cetera.

    :random,  # Conditions are randomly mapped to SRC, one after another. If all
              # conditions are exhausted, the condition specified in
              # reference_condition will be used.

    :random_live  # same as random, but the conditions will be added "live", on demand
                  # such that all conditions will be used first, including reference
                  # condition, then the reference condition until the experiment is finished
  ]

  # create empty ExperimentProgress relations for all existing users
  def create_progress_stubs
    User.find_each do |user|
      user.experiment_progresses.create(experiment: self, watched_sequences: [])
    end
  end

  # get the progress of the user for the current experiment
  def user_progress(user)
    user.experiment_progresses.find_by experiment: self
  end

  def delete_all_test_data
    experiment_progresses.find_each do |experiment_progress|
      experiment_progress.sequence_results.destroy_all
      experiment_progress.status = "assigned"
      experiment_progress.save
      puts "Deleted data from experiment progress #{experiment_progress.id} with user #{experiment_progress.user.id}"
    end
  end

end
