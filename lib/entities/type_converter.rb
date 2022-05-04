# frozen_string_literal: true

require_relative '../errors'

module Entities
  module TypeConverter
    @types = {
      'boolean' => {
        string_converter: ->(name, value) {
          raise Errors::EntityInvalid.new(name.to_s => '类型错误') unless ['true', 'false'].include?(value.downcase)

          value == 'true'
        },
        class_matcher: [TrueClass, FalseClass]
      },
      'integer' => {
        string_converter: ->(name, value) {
          raise Errors::EntityInvalid.new(name.to_s => '类型错误') unless value =~ /^[+-]?\d+$/

          value.to_i
        },
        class_matcher: [Integer]
      },
      'number' => {
        string_converter: ->(name, value) {
          raise Errors::EntityInvalid.new(name.to_s => '类型错误') unless value =~ /^[+-]?\d+(\.\d+)?$/

          value.to_f
        },
        class_matcher: [Numeric]
      },
      'string' => {
        string_converter: ->(name, value) { value },
        class_matcher: [String]
      },
      'array' => {
        class_matcher: [Array]
      }
      # 'object' 类型要单独处理
    }

    class << self
      def convert_value(name, value, type)
        return nil if value.nil?
        return value.to_s if type == 'string' # 字符串类型的参数直接返回字符串表示
        return convert_string_value_to_specific_type(name, value, type) if value.is_a?(String) && type != 'string'

        # 默认情况下需要类型匹配
        raise Errors::EntityInvalid.new(name.to_s => '类型错误') unless match_type?(value, type)

        value
      end

      private

      def convert_string_value_to_specific_type(name, value, type)
        raise Errors::EntityInvalid.new(name.to_s => '类型错误') unless @types.key?(type) && @types[type].key?(:string_converter)

        @types[type][:string_converter].call(name, value)
      end

      def match_type?(value, type)
        if type == 'object'
          classes = @types.values.map { |value| value[:class_matcher] }.flatten
          classes.all? { |klass| !value.is_a?(klass) }
        else
          raise "未知的类型：#{type}" unless @types.key?(type) && @types[type].key?(:class_matcher)

          @types[type][:class_matcher].any? { |klass| value.class <= klass }
        end
      end
    end
  end
end
