# frozen_string_literal: true

module Errors
  class NoMatchingRouteError < StandardError; end
  class ParameterInvalid < StandardError; end
  class NotAuthorized < StandardError; end
end
