# frozen_string_literal: true

require 'bigdecimal'

module Meta
  module JsonSchema
    class ObjectWrapper
      def initialize(target)
        @target = target
      end

      def __target__
        @target
      end

      def key?(key)
        @target.respond_to?(key)
      end

      def [](key)
        @target.__send__(key)
      end

      def method_missing(method, *args)
        @target.__send__(method, *args)
      end
    end

    module TypeConverter
      # 定义客户类型对应的 Ruby 类型
      @definity_types = {
        'boolean' => [TrueClass, FalseClass],
        'integer' => [Integer],
        'number' => [Integer, Float, BigDecimal],
        'string' => [String],
        'array' => [Array],
        'object' => [Hash, ObjectWrapper]
      }

      # 定义从 Ruby 类型转化为对应类型的逻辑
      @boolean_converters = {
        [String] => lambda do |value|
          unless %w[true True TRUE false False FALSE].include?(value)
            raise TypeConvertError, I18n.t(:'json_schema.errors.type_convert.basic', target_type: 'boolean', value: value)
          end

          value.downcase == 'true'
        end
      }

      @integer_converters = {
        [String] => lambda do |value|
          # 允许的格式：+34、-34、34、34.0 等
          unless value =~ /^[+-]?\d+(\.0+)?$/
            raise TypeConvertError, I18n.t(:'json_schema.errors.type_convert.basic', target_type: 'integer', value: value)
          end

          value.to_i
        end,
        [Float, BigDecimal] => lambda do |value|
          unless value.to_i == value
            raise TypeConvertError, I18n.t(:'json_schema.errors.type_convert.basic', target_type: 'integer', value: value)
          end

          value.to_i
        end
      }

      @number_converters = {
        [String] => lambda do |value|
          unless value =~ /^[+-]?\d+(\.\d+)?$/
            raise TypeConvertError, I18n.t(:'json_schema.errors.type_convert.basic', target_type: 'number', value: value)
          end

          float = value.to_f
          float.to_i == float ? float.to_i : float
        end
      }

      @string_converters = {
        [Object] => lambda do |value|
          value.to_s
        end
      }

      @array_converters = {
        [Object] => lambda do |value|
          unless value.respond_to?(:to_a)
            raise TypeConvertError, I18n.t(:'json_schema.errors.type_convert.array')
          end

          value.to_a
        end
      }

      @object_converters = {
        [Object] => lambda do |value|
          if [TrueClass, FalseClass, Integer, Float, String].any? { |ruby_type| value.is_a?(ruby_type) }
            raise TypeConvertError, I18n.t(:'json_schema.errors.type_convert.object', value: value, real_type: I18n.t(:'json_schema.type_names.basic'))
          elsif value.is_a?(Array)
            raise TypeConvertError, I18n.t(:'json_schema.errors.type_convert.object', value: value, real_type: I18n.t(:'json_schema.type_names.array'))
          end

          ObjectWrapper.new(value)
        end
      }

      class << self
        def convert_value(value, target_type)
          return nil if value.nil?
          raise JsonSchema::TypeConvertError, I18n.t(:'json_schema.errors.type_convert.unknown') unless @definity_types.keys.include?(target_type)
          return value if match_definity_types?(value, target_type)

          convert_to_definity_type(value, target_type)
        end

        private

          def match_definity_types?(value, target_type)
            ruby_types = @definity_types[target_type]
            return ruby_types.any?{ |ruby_type| value.is_a?(ruby_type) }
          end

          def convert_to_definity_type(value, target_type)
            converters = instance_variable_get(:"@#{target_type}_converters")
            converters.each do |ruby_types, converter|
              if ruby_types.any?{ |ruby_type| value.is_a?(ruby_type) }
                return converter.call(value)
              end
            end
            raise TypeConvertError, I18n.t(:'json_schema.errors.type_convert.basic', target_type: target_type, value: value)
          end
      end
    end

    class TypeConvertError < StandardError
    end
  end
end
