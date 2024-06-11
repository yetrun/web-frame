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

require_relative 'consumers'
require_relative 'extras_consumers'
require_relative 'checker'

module Meta
  module Utils
    class Kwargs
      class Builder
        def initialize
          @arguments = []
          @handle_extras = ExtrasConsumers::RaiseError
        end

        def key(*names, **options)
          names.each do |name|
            @arguments << ArgumentConsumer.new(name: name, **options)
          end
        end

        def handle_extras(sym)
          @handle_extras = ExtrasConsumers.resolve_handle_extras(sym)
        end

        def after_handler(&blk)
          @after_handler = blk
        end

        def build(base_consumer = nil)
          consumers = [base_consumer, *@arguments].compact
          consumers = CompositeConsumer.new(*consumers)
          Checker.new(arguments_consumer: consumers, extras_consumer: @handle_extras, after_handler: @after_handler)
        end

        def self.build(base_checker = nil, &block)
          builder = Builder.new
          builder.instance_exec &block
          builder.build(base_checker&.arguments_consumer)
        end
      end
    end
  end
end
