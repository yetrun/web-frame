module Dain
  class PathMatchingMod < Module
    def initialize(path_method: :path, matching_mode: :full)
      @path_method = path_method
      @matching_mode = matching_mode
    end

    def included(base)
      path_method = @path_method
      matching_mode = @matching_mode

      base.class_eval do
        define_method(:path_matching) do
          @_path_matching ||= PathMatching.new(send(path_method), matching_mode)
        end
      end
    end
  end

  class PathMatching
    def initialize(path_schema, matching_mode)
      raw_regex = path_schema
                    .gsub(/:(\w+)/, '(?<\1>[^/]+)')
                    .gsub(/\*(\w+)/, '(?<\1>.+)')
                    .gsub(/:/, '[^/]+').gsub('*', '.+')
      @path_matching_regex = matching_mode == :prefix ? Regexp.new("^#{raw_regex}") : Regexp.new("^#{raw_regex}$")
    end

    def match?(real_path)
      @path_matching_regex.match?(real_path)
    end

    def merge_path_params(path, request)
      path_params, remaining_path = capture_both(path)
      path_params.each { |name, value| request.update_param(name, value) }
      remaining_path
    end

    def capture_both(real_path)
      real_path = '' if real_path == '/'
      m = @path_matching_regex.match(real_path)
      [m.named_captures, m.post_match]
    end

    def capture_named_params(real_path)
      capture_both(real_path)[0]
    end

    def capture_remaining_part(real_path)
      capture_both(real_path)[1]
    end
  end
end
