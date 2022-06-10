# frozen_string_literal: true

module JsonSchema
  module HashExtension
    def [](key)
      @validators[key]
    end

    def []=(key, validator)
      @validators[key] = validator
    end

    def delete(key)
      @validators.delete(key)
    end
  end

  module ObjectValidators
    @validators = {
      required: proc { |params, names|
        missing_names = names.find_all { |name| params[name.to_s].nil? }

        errors = missing_names.to_h { |name| [name.to_s, '未提供'] }
        raise JsonSchema::ValidationErrors.new(errors)
      }
    }

    class << self
      include HashExtension
    end
  end

  module BaseValidators
    @validators = {
      format: proc { |value, format|
        raise JsonSchema::ValidationError, '格式不正确' unless value =~ format
      }
    }

    class << self
      include HashExtension
    end
  end
end
