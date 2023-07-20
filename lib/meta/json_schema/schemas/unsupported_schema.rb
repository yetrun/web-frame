# frozen_string_literal: true

module Meta
  module JsonSchema
    class UnsupportedSchema < BaseSchema
      attr_reader :key, :value

      def initialize(key, value)
        @key = key
        @value = value
      end

      def filter?
        false
      end

      def filter(value, options)
        raise UnsupportedError, "不支持的 #{key}: #{value}}"
      end
    end
  end
end
