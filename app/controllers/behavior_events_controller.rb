class BehaviorEventsController < ApplicationController

  def create
    @sequence_result = SequenceResult.find(params[:sequence_result_id])

    if not @sequence_result
      render json: {
        error: "No such sequence result"
      }
      return
    end

    unless params[:value].nil?
      begin
        value = JSON.parse(params[:value])
      rescue
        value = params[:value]
      end
    end

    @behavior_event = BehaviorEvent.new({
      sequence_result: @sequence_result,
      type: params[:type],
      value: value,
      client_time: Time.at(params[:client_time].to_f / 1000)
    })

    if @behavior_event.save()
      render json: {} and return
    else
      render json: {
        error: @behavior_event.errors.inspect
      }
      return
    end
  end

end
