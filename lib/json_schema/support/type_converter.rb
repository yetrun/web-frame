# frozen_string_literal: true

module Dain
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
        'number' => [Integer, Float],
        'string' => [String],
        'array' => [Array],
        'object' => [Hash, ObjectWrapper]
      }

      # 定义从 Ruby 类型转化为对应类型的逻辑
      @boolean_converters = {
        [String] => lambda do |value|
          unless %w[true True TRUE false False FALSE].include?(value)
            raise TypeConvertError, "类型转化失败，期望得到一个 `boolean` 类型，但值 `#{value}` 无法转化"
          end

          value.downcase == 'true'
        end
      }

      @integer_converters = {
        [String] => lambda do |value|
          # 允许的格式：+34、-34、34、34.0 等
          unless value =~ /^[+-]?\d+(\.0+)?$/
            raise TypeConvertError, "类型转化失败，期望得到一个 `integer` 类型，但值 `#{value}` 无法转化"
          end

          value.to_i
        end,
        [Float] => lambda do |value|
          unless value.to_i == value
            raise TypeConvertError, "类型转化失败，期望得到一个 `integer` 类型，但值 `#{value}` 无法转化"
          end

          value.to_i
        end
      }

      @number_converters = {
        [String] => lambda do |value|
          unless value =~ /^[+-]?\d+(\.\d+)?$/
            raise TypeConvertError, "类型转化失败，期望得到一个 `number` 类型，但值 `#{value}` 无法转化"
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
            raise TypeConvertError, "转化为数组类型时期望对象拥有 `to_a` 方法"
          end

          value.to_a
        end
      }

      @object_converters = {
        [Object] => lambda do |value|
          if [TrueClass, FalseClass, Integer, Float, String].any? { |ruby_type| value.is_a?(ruby_type) }
            raise TypeConvertError, "类型转化失败，期望得到一个 `object` 类型，但值 `#{value}` 是一个基本类型"
          elsif value.is_a?(Array)
            raise TypeConvertError, "类型转化失败，期望得到一个 `object` 类型，但值 `#{value}` 是一个 `array` 类型"
          end

          ObjectWrapper.new(value)
        end
      }

      class << self
        def convert_value(value, target_type)
          return nil if value.nil?
          raise JsonSchema::TypeConvertError, "未知的目标类型 `#{target_type}`" unless @definity_types.keys.include?(target_type)
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
            raise TypeConvertError, "类型转化失败，期望得到一个 `#{target_type}` 类型，但值 `#{value}` 无法转化"
          end
      end
    end

    class TypeConvertError < StandardError
    end
  end
end
