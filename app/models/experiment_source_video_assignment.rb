class ExperimentSourceVideoAssignment < ActiveRecord::Base

    belongs_to :experiment
    belongs_to :source_video

end
