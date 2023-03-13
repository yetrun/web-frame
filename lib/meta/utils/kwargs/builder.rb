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
      def initialize(arguments)
        @arguments = arguments
      end

      def check(args)
        args = args.dup
        final_args = {}

        @arguments.each do |argument|
          argument.consume!(final_args, args)
        end

        unless args.keys.empty?
          extras = args.keys
          raise "不接受额外的关键字参数：#{extras.join(', ')}" unless extras.empty?
        end

        final_args
      end

      class Argument
        DEFAULT_TRANSFORMER = ->(value) { value }

        def initialize(name:, normalizer: DEFAULT_TRANSFORMER)
          @name = name
          @normalizer = normalizer
        end

        def consume!(final_args, args)
          if args.key?(@name)
            value = @normalizer.call(args.delete(@name))
            final_args[@name] = value
          end
        end
      end

      class Builder
        def initialize
          @arguments = []
        end

        def key(*names, **options)
          names.each do |name|
            @arguments << Argument.new(name: name, **options)
          end
        end

        def build
          KeywordArgs.new(@arguments)
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
