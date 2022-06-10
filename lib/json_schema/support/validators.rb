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
      required: proc { |value, options, full_options|
        next if options == false

        full_options ||= {}
        options = {} if options == true
        raise JsonSchema::ValidationError, '未提供' if value.nil?

        if full_options[:type] == 'string' && (!options[:allow_empty]) && value.empty?
          raise JsonSchema::ValidationError, '未提供'
        end
        if full_options[:type] == 'array' && (options[:allow_empty] == false) && value.empty?
          raise JsonSchema::ValidationError, '未提供'
        end
      },
      format: proc { |value, format|
        raise JsonSchema::ValidationError, '格式不正确' unless value =~ format
      }
    }

    class << self
      include HashExtension
    end
  end
end
