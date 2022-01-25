class Condition < ActiveRecord::Base

  has_many :test_sequences
  has_many :experiment_condition_assignments
  has_many :experiments, through: :experiment_condition_assignments

  validates :cond_id, presence: true, uniqueness: true

  serialize :player_params

  # Assigns all conditions to all existing experiments
  def self.assign_to_all_experiments
    Condition.find_each do |condition|
      Experiment.find_each do |exp|
        condition.experiments << exp
        condition.save
      end
    end
  end

end
