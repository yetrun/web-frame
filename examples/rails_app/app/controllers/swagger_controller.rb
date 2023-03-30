class SwaggerController < ApplicationController
  def get_spec
    # 需要提前加载控制器常量，如以下两种方式：
    # - Rails.application.eager_load!
    # - Dir.glob(Rails.root.join('app', 'controllers', '**', '*.rb')).each { |f| require f }
    #
    # 这里仅仅仅仅使用了 require_relative
    require_relative 'data_controller'

    doc = Meta::Rails::Plugin.generate_swagger_doc(ApplicationController)
    render json: doc
  end
end
