# 作为 Rails 插件

require_relative 'schemas'

module Meta
  module JsonSchema
    module Rails
      module Plugin
        def self.included(base)
          # 为 ActionController 引入宏命令，宏命令在子类中生效
          base.extend ClassMethods

          # 为 ActionController 定义一个存储器，子类实例可以通过 self.class.params_definitions 访问
          params_definitions = {}
          base.define_singleton_method(:params_definitions) { params_definitions }

          # 定义一个方法，子类在定义方法后，将当前的 params 定义应用到该方法上
          base.define_singleton_method(:apply_params_definition) do |klass, method_name|
            if @current_params_definition
              self.params_definitions[[klass, method_name]] = @current_params_definition
              @current_params_definition = nil
            end
          end
          # 触发 apply_params_definition 方法
          base.define_singleton_method(:method_added) do |name|
            apply_params_definition(self, name)
          end

          # 为 ActionController 定义一个方法，用于获取过滤后的参数
          attr_accessor :raw_params

          # 为 ActionController 定义一个 before_action，用于过滤参数
          base.before_action do
            self.raw_params = params

            controller_class = self.class
            method_name = params[:action].to_sym
            params_schema = controller_class.params_definitions[[controller_class, method_name]]
            filtered_params = params_schema.filter(params.to_unsafe_hash) if params_schema
            self.params = { controller: params[:controller], action: params[:action] }.merge(filtered_params)
          end
        end

        module ClassMethods
          def params(&block)
            @current_params_definition = ::Meta::JsonSchema::SchemaBuilderTool.build(&block)
          end
        end
      end
    end
  end
end
