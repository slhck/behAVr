class SequenceResultsController < ApplicationController

  before_action :verify_admin, only: :show

  def show
    @sequence_result = SequenceResult.find(params[:id])
  end

  def new_ratings
    @sequence_result = SequenceResult.find(params[:sequence_result_id])
    @experiment = @sequence_result.experiment_progress.experiment

    @sequence_result.ratings.destroy_all

    # create empty ratings
    @experiment.rating_prototypes.all.each do |rating_prototype|
      @sequence_result.ratings.new(rating_prototype: rating_prototype)
    end

    render action: :new_ratings, layout: 'experiment'
  end

  def save_ratings
    @sequence_result = SequenceResult.find(params[:sequence_result_id])
    @experiment = @sequence_result.experiment_progress.experiment

    # FIXME: this is not nice, security problems
    params.require(:sequence_result).permit!

    # create rating objects
    ratings = []
    params[:sequence_result][:ratings_attributes].each_value do |rating_attributes|
      rating = @sequence_result.ratings.new(rating_attributes)
      ratings << rating
    end

    # try to save ratings
    errored = false
    Rating.transaction do
      ratings.each do |r|
        if not r.save
          errored = true
          raise ActiveRecord::Rollback
        end
      end
    end

    if errored
      flash[:error] = t(:fill_all_required_fields)
      render action: :new_ratings, layout: 'experiment'
    else
      redirect_to sequencelist_experiment_url(@experiment)
    end


  end

end
