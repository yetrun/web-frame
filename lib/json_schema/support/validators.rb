# frozen_string_literal: true

module Dain
  module JsonSchema
    module Validators
      @validators = {
        validate: proc { |value, p| p.call(value) },
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
        },
        allowable: proc { |value, allowable_values|
          raise JsonSchema::ValidationError, '不在允许的值范围内' unless allowable_values.include?(value)
        }
      }

      class << self
        def [](key)
          @validators[key]
        end

        def []=(key, validator)
          @validators[key] = validator
        end

        def delete(key)
          @validators.delete(key)
        end

        def keys
          @validators.keys
        end
      end
    end
  end
end
