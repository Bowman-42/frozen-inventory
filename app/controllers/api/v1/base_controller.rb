class Api::V1::BaseController < ApplicationController
  protect_from_forgery with: :null_session
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found(exception)
    render json: { error: 'Record not found', message: exception.message }, status: :not_found
  end

  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end

  def render_success(data, message = nil)
    response = { data: data }
    response[:message] = message if message
    render json: response, status: :ok
  end
end
