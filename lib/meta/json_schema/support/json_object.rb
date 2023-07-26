# frozen_string_literal: true

# 将 Ruby 类型包装成 JsonObject 类型，以便可以通过 [key] 访问。同时，保留其他方法的调用，将其转发到原始对象上。
module Meta
  module JsonSchema
    class JsonObject
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

      def self.wrap(target)
        case target
        when JsonObject, Hash
          target
        else
          new(target)
        end
      end
    end
  end
end
