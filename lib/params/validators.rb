# frozen_string_literal: true

module Params
  class ObjectScope
    module Validators
      @validators = {
        required: ->(params, names, path) {
          missing_param = names.find { |name| params[name.to_s].nil? }

          if missing_param
            p = path.empty? ? missing_param : "#{path}.#{missing_param}"
            raise Errors::ParameterInvalid, "缺少必传参数 `#{p}`"
          end
        }
      }

      class << self
        def [](key)
          @validators[key]
        end
      end
    end

    def required(*names)
      validates :required, names
    end
  end

  class PrimitiveScope
    module Validators
      @validators = {
        format: ->(value, format, path) {
          raise Errors::ParameterInvalid, "参数 `#{path}` 格式不正确" unless value =~ format
        }
      }

      class << self
        def [](key)
          @validators[key]
        end
      end
    end
  end
end
