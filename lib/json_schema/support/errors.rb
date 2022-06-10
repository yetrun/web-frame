# frozen_string_literal: true

module JsonSchema
  class ValidationErrors < StandardError
    attr_reader :errors

    def initialize(errors, message = nil)
      raise ArgumentError, '参数 errors 应传递一个 Hash' unless errors.is_a?(Hash)

      super(message)
      @errors = errors
    end

    def prepend_root(root)
      errors_prepend_root = errors.transform_keys do |name|
        return name.to_s if root.empty?

        path = name[0] == '[' ? "#{root}#{name}" : "#{root}.#{name}"
        path = path[1..] if path[0] == '.'
        path = path[0..-2] if path[-1] == '.'
        path
      end
      ValidationErrors.new(errors_prepend_root)
    end
  end

  class ValidationError < ValidationErrors
    def initialize(message)
      super('' => message)
    end

    def message
      errors['']
    end
  end
end
