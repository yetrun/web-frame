# frozen_string_literal: true

module Errors
  class ParameterInvalid < StandardError
  end

  class NoMatchingRouteError < StandardError
  end
end
