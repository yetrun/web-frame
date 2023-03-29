require 'meta/rails'

class ApplicationController < ActionController::API
  include Meta::Rails::Plugin

  rescue_from Meta::JsonSchema::ValidationErrors do |e|
    render json: e.errors, status: :bad_request
  end
end
