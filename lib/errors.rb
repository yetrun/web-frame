# frozen_string_literal: true

module Errors
  class NoMatchingRoute < StandardError; end

  class EntityInvalid < StandardError
    attr_reader :errors

    def initialize(errors, message = nil)
      raise ArgumentError, '参数 errors 应传递一个 Hash' unless errors.is_a?(Hash)

      super(message)
      @errors = errors
    end
  end

  class ParameterInvalid < EntityInvalid
    def initialize(errors)
      super(errors, "参数异常：#{errors}")
    end
  end

  class RenderingInvalid < EntityInvalid
    def initialize(errors)
      super(errors, "渲染实体异常：#{errors}")
    end
  end

  class NotAuthorized < StandardError; end
end
