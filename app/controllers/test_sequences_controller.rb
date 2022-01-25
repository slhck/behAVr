class TestSequencesController < ApplicationController

  before_filter :set_test_sequence

  def watch

    # Re-use or create new sequence result if necessary
    @experiment = Experiment.find(params[:experiment_id])
    @experiment_progress = ExperimentProgress.find_by experiment: @experiment, user: current_user

    result_params = {
      user:                current_user,
      experiment_progress: @experiment_progress,
      test_sequence:       @test_sequence
    }
    @sequence_result = SequenceResult.find_by result_params

    # If no result exists, user is watching this fir the first time
    if not @sequence_result
      @sequence_result = SequenceResult.create(result_params)

      # also assign a new condition if this experiment uses the
      # random_live mapping
      condition = @experiment_progress.get_random_unrated_condition
      @test_sequence.condition = condition
      @test_sequence.save
    end

    render action: :watch, layout: 'experiment'
  end

  def set_test_sequence
    if params[:id]
      @test_sequence = TestSequence.find(params[:id])
    elsif params[:test_sequence_id]
      @test_sequence = TestSequence.find(params[:test_sequence_id])
    end
  end

end
