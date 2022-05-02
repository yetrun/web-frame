# frozen_string_literal: true

module Entities
  module ObjectValidators
    @validators = {
      required: ->(params, names, path) {
        missing_param = names.find { |name| params[name.to_s].nil? }

        if missing_param
          p = path.empty? ? missing_param : "#{path}.#{missing_param}"
          raise Errors::EntityInvalid.new(p.to_s => '未提供')
        end
      }
    }

    class << self
      def [](key)
        @validators[key]
      end
    end
  end

  module BaseValidators
    @validators = {
      format: ->(value, format, path) {
        raise Errors::EntityInvalid.new(path.to_s => '格式不正确') unless value =~ format
      }
    }

    class << self
      def [](key)
        @validators[key]
      end
    end
  end
end
