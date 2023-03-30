class ApplicationController < ActionController::API
  rescue_from Meta::JsonSchema::ValidationErrors do |e|
    render json: e.errors, status: :bad_request
  end
end
