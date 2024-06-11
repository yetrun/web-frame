# frozen_string_literal: true

module Meta
  module Utils
    class Kwargs
      module ExtrasConsumers
        Ignore = ProcConsumer.new
        Merged = ProcConsumer.new do |final_args, args|
          final_args.merge!(args)
        end
        RaiseError = ProcConsumer.new do |final_args, args|
          extras_keys = args.keys
          raise ArgumentError, "不接受额外的关键字参数：#{extras_keys.join(', ')}" unless extras_keys.empty?
        end

        def self.resolve_handle_extras(sym)
          return nil if sym.nil?

          case sym
          when :ignore
            ExtrasConsumers::Ignore
          when :merged
            ExtrasConsumers::Merged
          when :raise_error
            ExtrasConsumers::RaiseError
          else
            raise ArgumentError, "handle_extras 只接受 :ignore, :merged, :raise_error 三种值，当前传递：#{sym}"
          end
        end
      end
    end
  end
end
