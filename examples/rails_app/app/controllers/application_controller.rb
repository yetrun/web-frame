class ApplicationController < ActionController::API
  include Meta::Rails::Plugin

  rescue_from Meta::Errors::ParameterInvalid do |e|
    render json: e.errors, status: :bad_request
  end
end
