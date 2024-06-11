# frozen_string_literal: true

module Meta
  module Utils
    class Kwargs
      class ArgumentConsumer
        DEFAULT_TRANSFORMER = ->(value) { value }

        def initialize(name:, normalizer: DEFAULT_TRANSFORMER, validator: nil, default: nil, alias_names: [])
          @key_name = name
          @consumer_names = [name] + alias_names
          @default_proc = -> { default.dup } if default
          @normalizer = normalizer
          @validator = validator
        end

        def consume(final_args, args)
          @consumer_names.each do |name|
            return if consume_name(final_args, args, name)
          end

          if @default_proc
            default_value = @default_proc.call
            final_args[@key_name] = @normalizer.call(default_value)
          end
        end

        def consume_name(final_args, args, consumer_name)
          if args.key?(consumer_name)
            value = @normalizer.call(args.delete(consumer_name))
            @validator.call(value) if @validator
            final_args[@key_name] = value
            true
          else
            false
          end
        end
      end

      class ProcConsumer
        def initialize(&blk)
          @block = blk
        end

        def consume(final_args, args)
          @block.call(final_args, args) if @block
        end
      end

      class CompositeConsumer
        def initialize(*consumers)
          @consumers = consumers
        end

        def consume(final_args, args)
          @consumers.each do |consumer|
            consumer.consume(final_args, args)
          end
        end
      end

    end
  end
end
