# frozen_string_literal: true

module Dain
  module RouteDSL
    class ActionBuilder
      def initialize(&block)
        @block = block
      end

      def build
        @block
      end
    end
  end
end
