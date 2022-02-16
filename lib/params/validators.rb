# frozen_string_literal: true

module Params
  module Validators
    @validators = {
      format: ->(value, format) {
        raise Errors::ParameterInvalid, '参数格式不正确' unless value =~ format
      }
    }

    class << self
      def [](key)
        @validators[key]
      end
    end
  end
end
