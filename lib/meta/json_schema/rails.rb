# 作为 Rails 插件

require_relative 'schemas'

ActionController::Renderers.add :json_on_schema do |obj, options|
  options = options.dup
  status = options.delete(:status) || 200
  scope = options.delete(:scope) || :all

  route_definitions = self.class.route_definitions
  route_definition = route_definitions[[self.class, params[:action].to_sym]]
  if route_definition[:status] && route_definition[:status][status]
    render_schema = route_definition[:status][status]
    str = render_schema.filter(obj, execution: self, stage: :render, scope: scope)
    render json: str, **options
  end
end

module Meta
  module JsonSchema
    module Rails
      module Plugin
        def self.included(base)
          # 为 ActionController 引入宏命令，宏命令在子类中生效
          base.extend ClassMethods

          # 为 ActionController 定义一个 Route Definitions，子类实例可以通过 self.class.route_definitions 访问
          route_definitions = {}
          base.define_singleton_method(:route_definitions) { route_definitions }

          # 定义一个方法，子类在定义方法后，将当前的路由定义应用到该方法上
          base.define_singleton_method(:apply_route_definition) do |klass, method_name|
            if @current_route_definition
              self.route_definitions[[klass, method_name]] = @current_route_definition
              @current_route_definition = nil
            end
          end
          # 触发 apply_route_definition 方法
          base.define_singleton_method(:method_added) do |name|
            apply_route_definition(self, name)
          end

          # 为 ActionController 定义一个方法，用于获取过滤后的参数
          attr_accessor :raw_params

          # 为 ActionController 定义一个 before_action，用于过滤参数
          base.before_action do
            self.raw_params = params

            route_definitions = self.class.route_definitions
            route_definition = route_definitions[[self.class, params[:action].to_sym]]
            if route_definition[:params]
              params_schema = route_definition[:params]
              filtered_params = params_schema.filter(params.to_unsafe_hash, stage: :param)
              self.params = { controller: params[:controller], action: params[:action] }.merge(filtered_params)
            end
          end
        end

        module ClassMethods
          def params(&block)
            @current_route_definition ||= {}
            @current_route_definition[:params] = ::Meta::JsonSchema::SchemaBuilderTool.build(&block)
          end

          def status(code, &block)
            @current_route_definition ||= {}
            @current_route_definition[:status] ||= {}
            @current_route_definition[:status][code] = ::Meta::JsonSchema::SchemaBuilderTool.build(&block)
          end
        end
      end
    end
  end
end
