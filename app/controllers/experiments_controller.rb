class ExperimentsController < ApplicationController

  before_filter :set_experiment, except: [ :index ]

  def index
  end

  def show
  end

  def join
    ep = ExperimentProgress.find_by experiment: @experiment, user: current_user
    ep.update_attribute(:status, :joined)
    ep.update_attribute(:joined, Time.now)
    redirect_to introduction_experiment_url(@experiment)
  end

  def unjoin
    ep = ExperimentProgress.find_by experiment: @experiment, user: current_user
    ep.update_attribute(:status, :assigned)
    # TODO: delete progress
    redirect_to experiment_url(@experiment)
  end

  def introduction
    render action: :introduction, layout: 'experiment'
  end

  def sequencelist
    ep = ExperimentProgress.find_by experiment: @experiment, user: current_user
    if ep.finished_main_part?
      flash[:notice] = I18n.t(:congrats_finished)
    end
    render action: :sequencelist, layout: 'experiment'
  end

  def outro
    render action: :outro, layout: 'experiment'
  end

  def finished
    render action: :finished, layout: 'experiment'
  end

  def finish
    ep = ExperimentProgress.find_by experiment: @experiment, user: current_user
    ep.update_attribute(:status, :finished)
    ep.update_attribute(:finished, Time.now)
    redirect_to outro_experiment_url(@experiment)
  end

  def complete_introduction
    if @experiment.access_key.nil? or params[:key].downcase == @experiment.access_key.downcase
      ep = ExperimentProgress.find_by experiment: @experiment, user: current_user
      ep.update_attribute(:status, :started)
      ep.update_attribute(:started, Time.now)
      redirect_to sequencelist_experiment_url(@experiment)
    else
      flash[:error] = t(:wrong_access_key)
      redirect_to introduction_experiment_url(@experiment)
    end
  end

  def complete_outro
    if @experiment.finish_key.nil? or params[:key].downcase == @experiment.finish_key.downcase
      ep = ExperimentProgress.find_by experiment: @experiment, user: current_user
      ep.update_attribute(:status, :completed)
      ep.update_attribute(:completed, Time.now)
      redirect_to finished_experiment_url(@experiment)
    else
      flash[:error] = t(:wrong_finish_key)
      redirect_to outro_experiment_url(@experiment)
    end
  end

  def set_experiment
    if params[:id]
      @experiment = Experiment.find(params[:id])
    elsif params[:experiment_id]
      @experiment = Experiment.find(params[:experiment_id])
    end
  end

end
