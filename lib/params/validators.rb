# frozen_string_literal: true

module Params
  class ObjectScope
    module Validators
      @validators = {
        required: ->(params, names) {
          missing_any = names.any? do |name|
            params[name.to_s].nil? # 键不存在或值为 nil
          end
          raise Errors::ParameterInvalid, '有些必传参数没有传递' if missing_any
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
        format: ->(value, format) {
          raise Errors::ParameterInvalid, '参数格式不正确' unless value =~ format
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
