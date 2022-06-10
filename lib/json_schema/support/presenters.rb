# frozen_string_literal: true

module JsonSchema
  module Presenters
    @presenter_handlers = []

    class << self
      def register(presenter_handler)
        @presenter_handlers << presenter_handler
      end

      def unregister(presenter_handler)
        @presenter_handlers.delete(presenter_handler)
      end

      def present(presenter, value)
        @presenter_handlers.each do |presenter_handler|
          next unless presenter_handler.handle?(presenter)

          return presenter_handler.present(presenter, value)
        end
      end

      def to_schema(presenter, other_options)
        @presenter_handlers.each do |presenter_handler|
          next unless presenter_handler.handle?(presenter)

          return presenter_handler.to_schema(presenter, other_options)
        end
      end
    end
  end
end
