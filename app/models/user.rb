class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :experiment_progresses, dependent: :destroy
  has_many :experiments, through: :experiment_progresses
  has_many :user_test_sequence_assignments, dependent: :destroy
  has_many :test_sequences, through: :user_test_sequence_assignments

  after_create :create_progress_stubs, :assign_to_all_experiments

  # create empty ExperimentProgress relations for all existing users
  def create_progress_stubs
    Experiment.find_each do |experiment|
      experiment.experiment_progresses.create(user: self)
    end
  end

  # Assign this user to all experiments
  def assign_to_all_experiments
    self.experiment_progresses.find_each do |ep|
      ep.update_attribute(:status, :assigned)
    end
  end
end
