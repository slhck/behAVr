class TestSequence < ActiveRecord::Base

  belongs_to :experiment
  belongs_to :condition
  belongs_to :source_video
  has_many :sequence_results
  has_many :user_test_sequence_assignments
  has_many :users, through: :user_test_sequence_assignments

  validates :sequence_id, presence: true, uniqueness: true
  validates :condition, :source_video, presence: true

end
