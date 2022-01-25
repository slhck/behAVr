class ExperimentConditionAssignment < ActiveRecord::Base

    belongs_to :experiment
    belongs_to :condition

end
