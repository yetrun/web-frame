# 作为 Rails 插件

require_relative 'schemas'

ActionController::Renderers.add :json_on_schema do |obj, options|
  options = options.dup
  status = options.delete(:status) || 200
  scope = options.delete(:scope) || :all

  route_definitions = self.class.route_definitions
  route_definition = route_definitions[[self.class, params[:action].to_sym]]
  meta_definition = route_definition.meta
  if meta_definition[:responses] && meta_definition[:responses][status]
    render_schema = meta_definition[:responses][status]
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
          attr_accessor :raw_params

          # 为 ActionController 定义一个 before_action，用于过滤参数
          base.before_action do
            route_definitions = self.class.route_definitions
            route_definition = route_definitions[[self.class, params[:action].to_sym]]
            meta_definition = route_definition.meta
            unless meta_definition[:parameters].empty? || meta_definition[:request_body].nil?
              self.raw_params = params
              raw_params = params.to_unsafe_h
              final_params = {}

              if meta_definition[:parameters]
                parameters_meta = meta_definition[:parameters]
                final_params = parameters_meta.map do |name, options|
                  schema = options[:schema]
                  value = if options[:in] == 'header'
                            schema.filter(request.get_header('HTTP_' + name.to_s.upcase.gsub('-', '_')))
                          else
                            schema.filter(request.params[name.to_s])
                          end
                  [name, value]
                end.to_h
              end
              if meta_definition[:request_body]
                params_schema = meta_definition[:request_body]
                final_params.merge! params_schema.filter(raw_params, stage: :param)
              end

              self.params = { controller: raw_params['controller'], action: raw_params['action'], **final_params }
            end
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
end
