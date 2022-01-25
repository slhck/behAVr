class SequenceResult < ActiveRecord::Base

  belongs_to :experiment_progress
  belongs_to :test_sequence
  belongs_to :user
  has_many :behavior_events, dependent: :destroy
  has_many :ratings, dependent: :destroy

  accepts_nested_attributes_for :ratings

  def times_reloaded
    behavior_events.where(type: 'system.player.loaded').count - 1
  end

  def behavior_events_list
    # get a compact representation for stats
    behavior_events
    .order(:created_at)
    .map do |event|
      BehaviorEvent::ABBREVIATIONS[event.type]
    end
    .compact # remove NIL
    .chunk(&:itself).map(&:first) # remove dupes
    .join(" ")
  end
end
