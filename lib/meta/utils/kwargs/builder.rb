# frozen_string_literal: true

# 使用构建器构建关键字参数检查器。
#
# 在 Ruby 3 中，关键字参数有所变化。简单来说，关键字参数和 Hash 类型不再自动转化，并且一般情况下推荐使用关键字参数。
# 但关键字参数还是有稍稍不足之处，比如在做一些复杂的关键字参数定义时。
#
# 这个文件编写了一个方法，帮助我们在运行时检查关键字参数。这样，我们就可以像下面这样笼统的方式定义参数，不必用明确的关
# 键字参数名称。
#
#     def method_name(x, y, z, **kwargs); end
#     def method_name(x, y, z, kwargs={}); end
#
# 构建器使用示例：
#
#     Meta::Utils::KeywordArgs::Builder.build do
#       key :a, :b, :c
#       key :d, normalizer: ->(value) { normalize_to_array(value) }
#     end
#

module Meta
  module Utils
    class KeywordArgs
      def initialize(arguments, permit_extras = false, final_consumer = nil)
        @arguments = arguments
        @permit_extras = permit_extras
        @final_consumer = final_consumer
      end

      def check(args)
        args = args.dup
        final_args = {}

        @arguments.each do |argument|
          argument.consume(final_args, args)
        end

        # 做最终的修饰
        @final_consumer.call(final_args, args) if @final_consumer

        # 处理剩余字段
        unless args.keys.empty?
          if @permit_extras
            final_args.merge!(args)
          else
            extras = args.keys
            raise "不接受额外的关键字参数：#{extras.join(', ')}" unless extras.empty?
          end
        end

        final_args
      end

      class Argument
        DEFAULT_TRANSFORMER = ->(value) { value }

        def initialize(name:, normalizer: DEFAULT_TRANSFORMER, validator: nil, default: nil, alias_names: [])
          @key_name = name
          @consumer_names = [name] + alias_names
          @normalizer = default ? ->(value) { normalizer.call(value || default) } : normalizer
          @validator = validator
        end

        def consume(final_args, args)
          @consumer_names.each do |name|
            return true if consume_name(final_args, args, name)
          end
          return false
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

      class Builder
        def initialize
          @arguments = []
          @permit_extras = false
          @final_consumer = nil
        end

        def key(*names, **options)
          names.each do |name|
            @arguments << Argument.new(name: name, **options)
          end
        end

        def permit_extras(value)
          @permit_extras = value
        end

        def final_consumer(&block)
          @final_consumer = block
        end

        def build
          KeywordArgs.new(@arguments, @permit_extras, @final_consumer)
        end

        def self.build(&block)
          builder = Builder.new
          builder.instance_exec &block
          builder.build
        end
      end
    end
  end
end
