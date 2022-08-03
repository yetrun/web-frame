# frozen_string_literal: true

require_relative 'json_schema/schemas'

module Dain
  module Errors
    class NoMatchingRoute < StandardError; end

    class ParameterInvalid < JsonSchema::ValidationErrors
      def initialize(errors)
        super(errors, "参数异常：#{errors}")
      end
    end

    class RenderingInvalid < JsonSchema::ValidationErrors
      def initialize(errors)
        super(errors, "渲染实体异常：#{errors}")
      end
    end

    class RenderingError < StandardError; end

    class NotAuthorized < StandardError; end

    class NotFound < StandardError; end
  end
end
