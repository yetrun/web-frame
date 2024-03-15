# frozen_string_literal: true

require 'forwardable'
require_relative 'errors'
require_relative 'json_schema/schemas'

module Meta
  class Entity
    class << self
      extend Forwardable

      attr_reader :schema_builder

      def inherited(base)
        base.instance_eval do
          @schema_builder = JsonSchema::ObjectSchemaBuilder.new
          @schema_builder.schema_name(self.name) if self.name
        end
      end

      def method_missing(method, *args, **kwargs, &)
        schema_builder.send(method, *args, **kwargs, &)
      end

      private

      # TODO: 不需要在 Entity 内自动生成名称了，交给 ObjectSchema::Naming 去做吧
      def generate_schema_name(stage, locked_scopes)
        # 匿名类不考虑自动生成名称
        return nil unless self.name

        schema_name = self.name.gsub('::', '_')
        schema_name = schema_name.delete_suffix('Entity') unless schema_name == 'Entity'

        # 先考虑 stage
        case stage
        when :param
          schema_name += 'Params'
        when :render
          schema_name += 'Entity'
        end

        # 再考虑 locked_scope
        scope_suffix = locked_scopes.join('_')
        schema_name = "#{schema_name}_#{scope_suffix}" unless scope_suffix.empty?

        schema_name
      end
    end
  end
end
