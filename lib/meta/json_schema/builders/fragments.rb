# frozen_string_literal: true

module Meta
  module JsonSchema
    class Fragments
      def initialize(base_builder = nil, &)
        @base_builder = base_builder
        @fragments = {}
        instance_exec(&) if block_given?
      end

      def fragment(name, &block)
        @fragments[name] = block
      end

      def [](*names)
        # 先检查是否有不存在的 fragment
        names.each do |name|
          raise ArgumentError, "fragment #{name} 不存在" unless @fragments.key?(name)
        end

        schema_base_name = @base_builder&.schema_name
        fragments = @fragments.values_at(*names)
        ObjectSchemaBuilder.new do
          if schema_base_name
            schema_name "#{schema_base_name}__#{names.sort.join('__')}"
          end
          fragments.each { |fragment| instance_exec(&fragment) }
        end.to_schema
      end
    end
  end
end