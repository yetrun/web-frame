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
      end
    end
  end
end