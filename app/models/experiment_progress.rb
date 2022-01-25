class ExperimentProgress < ActiveRecord::Base
  belongs_to :user
  belongs_to :experiment
  has_many :sequence_results, dependent: :destroy

  enum status: [
    :unassigned,  # user is not assigned and cannot participate
    :assigned,    # user is assigned and may participate
    :joined,      # user joined the experiment but did not do anything yet (i.e. did not complete introduction)
    :started,     # user started the first sequence, that is, the main part of the experiment
    :finished,    # user finished the last sequence, that is, the main part of the experiment
    :completed    # user completed all the questionnaires or the final sequence in case of no questionnaires
  ]

  # has the user finished the main part depending on the condition set in experiment.yml?
  def finished_main_part?
    if self.experiment.finish_condition == "rated_all_conditions"
      unrated_condition_ids.empty?
    elsif self.experiment.finish_condition == "rated_all_sequences"
      unrated_sequence_ids.empty?
    else
      raise "No such finish condition implemented: #{self.experiment.finish_condition}"
    end
  end

  # all sequences that have been completely rated
  def rated_sequences
    self.sequence_results.where_exists(:ratings).map(&:test_sequence)
  end

  # all sequences that have been watched
  def watched_sequences
    self.sequence_results.map(&:test_sequence)
  end

  # all sequence IDs that have been completely rated
  def rated_sequence_ids
    rated_sequences.map(&:sequence_id)
  end

  # all sequence IDs that have been watched
  def watched_sequence_ids
    watched_sequences.map(&:sequence_id)
  end

  # all conditions that have been completely rated
  def rated_conditions
    self.sequence_results.where_exists(:ratings).map { |sr| sr.test_sequence.condition }
  end

  # all conditions that have been completely rated
  def rated_condition_ids
    rated_conditions.map(&:cond_id)
  end

  # returns an array of unrated condition IDs in this experiment
  def unrated_condition_ids
    all_condition_ids = self.experiment.conditions.all.map(&:cond_id).uniq
    all_condition_ids - rated_condition_ids
  end

  # returns an array of unrated sequence IDs in this experiment
  def unrated_sequence_ids
    all_sequence_ids   = self.user.test_sequences.all.map(&:sequence_id).uniq
    rated_sequence_ids = self.rated_sequences.map(&:sequence_id).uniq
    all_sequence_ids - rated_sequence_ids
  end

  # get a random condition that the user has not seen yet
  def get_random_unrated_condition
    # if all have been seen, return reference ID
    if unrated_condition_ids.empty?
      Condition.find_by cond_id: self.experiment.reference_condition
    # else return a random one, but start with reference
    else
      if rated_conditions.count == 0
        Condition.find_by cond_id: self.experiment.reference_condition
      else
        Condition.find_by cond_id: unrated_condition_ids.shuffle.shift
      end
    end
  end

  # to show how complete the user is
  def percent
    case status
    when "assigned"
      return 10
    when "joined"
      return 25
    when "started"
      return 50
    when "finished"
      return 75
    when "completed"
      return 100
    end
  end

  def verbal
    case status
    when "assigned"
      return I18n.t(:status_assigned)
    when "joined"
      return I18n.t(:status_joined)
    when "started"
      return I18n.t(:status_started)
    when "finished"
      return I18n.t(:status_finished)
    when "completed"
      return I18n.t(:status_completed)
    end
  end

end
