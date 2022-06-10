# frozen_string_literal: true

module JsonSchema
  module ObjectValidators
    @validators = {
      required: proc { |params, names|
        missing_param = names.find { |name| params[name.to_s].nil? }

        if missing_param
          raise JsonSchema::ValidationErrors.new(missing_param.to_s => '未提供')
        end
      }
    }

    class << self
      def [](key)
        @validators[key]
      end
    end
  end

  module BaseValidators
    @validators = {
      format: proc { |value, format|
        raise JsonSchema::ValidationError, '格式不正确' unless value =~ format
      }
    }

    class << self
      def [](key)
        @validators[key]
      end
    end
  end
end
