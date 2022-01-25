class RatingPrototype < ActiveRecord::Base

  default_scope { order(order: :asc) }

  belongs_to :experiment
  has_many :ratings

  translates :question

  validates :answer_type, inclusion: { in: %w(text five_star content_question),
    message: "%{value} is not a valid answer type." }

end
