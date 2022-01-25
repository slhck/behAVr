class Rating < ActiveRecord::Base

  belongs_to :sequence_result
  belongs_to :rating_prototype

  validate :required_answers_given

  def required_answers_given
    if rating_prototype.required and answer.empty?
      errors.add(:answer, I18n.t(:is_required))
    end
  end
end
