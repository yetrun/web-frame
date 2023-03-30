require_relative 'demo_controller'

class SwaggerController < ApplicationController
  def get_spec
    # Rails.application.eager_load!
    # Dir.glob(Rails.root.join('app', 'controllers', '**', '*.rb')).each { |f| require f }
    doc = Meta::Rails::Plugin.generate_swagger_doc(ApplicationController)
    render json: doc
  end
end
