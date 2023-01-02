# frozen_string_literal: true

module Meta
  module RouteDSL
    module Helpers
      class << self
        def join_path(*parts)
          parts = parts.map { |p| (p || '').delete_prefix('/').delete_suffix('/') }
          parts = parts.reject { |p| p.nil? || p.empty? }
          '/' + parts.join('/')
        end
      end
    end
  end
end
