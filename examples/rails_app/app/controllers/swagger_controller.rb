require_relative 'demo_controller'

class SwaggerController < ApplicationController
  def get_spec
    doc = ::Meta::Rails::Plugin.generate_swagger_doc(ApplicationController)
    render json: doc
  end
end
