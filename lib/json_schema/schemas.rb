# frozen_string_literal: true

require_relative 'support/type_converter'
require_relative 'schemas/base_schema'
require_relative 'schemas/object_schema'
require_relative 'schemas/array_schema'

module JsonSchema
  class ValidationError < StandardError
  end

  class ValidationErrors < StandardError
    attr_reader :errors

    def initialize(errors, message = nil)
      raise ArgumentError, '参数 errors 应传递一个 Hash' unless errors.is_a?(Hash)

      super(message)
      @errors = errors
    end
  end
end
