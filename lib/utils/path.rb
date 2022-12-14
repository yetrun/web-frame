# frozen_string_literal: true

module Dain
  module Utils
    class Path
      class << self
        def normalize_path(path)
          path = '/' unless path
          path = '/' + path unless path.start_with?('/')
          path = path.delete_suffix('/') if path.end_with?('/')
          path
        end

        def join(p1, p2)
          normalize_path(normalize_path(p1) + '/' + normalize_path(p2))
        end
      end
    end
  end
end
