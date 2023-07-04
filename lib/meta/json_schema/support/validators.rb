# frozen_string_literal: true

module Meta
  module JsonSchema
    module Validators
      @validators = {
        validate: proc { |value, p|
          next if value.nil?
          p.call(value)
        },
        required: proc { |value, options, full_options|
          next if options == false

          full_options ||= {}
          options = {} if options == true
          raise JsonSchema::ValidationError, I18n.t(:'json_schema.errors.required') if value.nil?

          if full_options[:type] == 'string' && (!options[:allow_empty]) && value.empty?
            raise JsonSchema::ValidationError, I18n.t(:'json_schema.errors.required')
          end
          if full_options[:type] == 'array' && (options[:allow_empty] == false) && value.empty?
            raise JsonSchema::ValidationError, I18n.t(:'json_schema.errors.required')
          end
        },
        format: proc { |value, format|
          next if value.nil?
          raise JsonSchema::ValidationError, I18n.t(:'json_schema.errors.format') unless value =~ format
        },
        allowable: proc { |value, allowable_values|
          next if value.nil?
          raise JsonSchema::ValidationError, I18n.t(:'json_schema.errors.allowable', allowable_values: allowable_values) unless allowable_values.include?(value)
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
