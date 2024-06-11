# frozen_string_literal: true

module Meta
  module Utils
    class Kwargs
      class Checker
        attr_reader :arguments_consumer

        def initialize(arguments_consumer:, extras_consumer: nil, after_handler: nil)
          @arguments_consumer = arguments_consumer
          @extras_consumer = extras_consumer || ExtrasConsumers::RaiseError
          @after_handler = after_handler
        end

        def check(args, extras_handler: nil)
          # 准备工作
          args = args.dup
          final_args = {}

          # 逐个消费参数
          @arguments_consumer.consume(final_args, args)

          # 处理额外参数
          extras_consumer = ExtrasConsumers.resolve_handle_extras(extras_handler)
          extras_consumer ||= @extras_consumer
          extras_consumer&.consume(final_args, args)

          # 后置处理器
          @after_handler&.call(final_args)

          # 返回最终参数
          final_args
        end
      end
    end
  end
end
