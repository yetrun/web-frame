# 作为 Rails 插件

require_relative 'errors'
require_relative 'json_schema/schemas'

module Meta
  module Rails
    def self.setup
      # 第一步，为 ActionController 添加一个新的 Renderer
      ActionController::Renderers.add :json_on_schema do |obj, options|
        options = options.dup
        status = options.delete(:status) || 200
        scope = options.delete(:scope) || :all

        route_definitions = self.class.route_definitions
        route_definition = route_definitions[[self.class, params[:action].to_sym]]
        raise '未绑定 Route 定义' unless route_definition

        meta_definition = route_definition.meta
        raise '未提供 status 宏定义' unless meta_definition[:responses] && meta_definition[:responses][status]

        render_schema = meta_definition[:responses][status]
        str = render_schema.filter(obj, execution: self, stage: :render, scope: scope)
        render json: str, **options
      rescue JsonSchema::ValidationErrors => e
        raise Errors::RenderingInvalid.new(e.errors)
      end
    end

    module Plugin
      def self.generate_swagger_doc(klass)
        paths_and_routes = klass.route_definitions.values.map do |route_definition|
          [route_definition.path, route_definition]
        end
        SwaggerDocUtil.generate_from_paths_and_routes(paths_and_routes)
      end

      def self.included(base)
        # 已经被父类引入过，不再重复引入
        return if self.respond_to?(:route_definitions)

        # 为 ActionController 引入宏命令，宏命令在子类中生效
        base.extend ClassMethods

        # 为 ActionController 定义一个 Route Definitions，子类实例可以通过 self.class.route_definitions 访问
        route_definitions = {}
        base.define_singleton_method(:route_definitions) { route_definitions }

        # 定义一个方法，子类在定义方法后，将当前的路由定义应用到该方法上
        base.define_singleton_method(:apply_route_definition) do |klass, method_name|
          if @current_route_builder
            self.route_definitions[[klass, method_name]] = @current_route_builder.build
            @current_route_builder = nil
          end
        end
        # 触发 apply_route_definition 方法
        base.define_singleton_method(:method_added) do |name|
          apply_route_definition(self, name)
        end

        # 为 ActionController 定义一个方法，用于获取过滤后的参数
        attr_accessor :params_on_schema

        # 为 ActionController 定义一个 before_action，用于过滤参数
        base.before_action do
          route_definitions = self.class.route_definitions
          route_definition = route_definitions[[self.class, params[:action].to_sym]]
          next unless route_definition

          meta_definition = route_definition.meta
          next if meta_definition[:parameters].empty? || meta_definition[:request_body].nil?

          raw_params = self.params.to_unsafe_h
          final_params = {}

          if meta_definition[:parameters]
            parameters_meta = meta_definition[:parameters]
            final_params = parameters_meta.filter(request)
          end
          if meta_definition[:request_body]
            params_schema = meta_definition[:request_body]
            final_params.merge! params_schema.filter(raw_params, stage: :param)
          end

          self.params_on_schema = final_params
        rescue JsonSchema::ValidationErrors => e
          raise Errors::ParameterInvalid.new(e.errors)
        end
      end

      module ClassMethods
        def route(path = '', method = :all, &block)
          @current_route_builder = RouteDSL::RouteBuilder.new(path, method, &block)
        end
      end
    end
  end
end
