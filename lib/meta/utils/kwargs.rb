# frozen_string_literal: true

# 运行时检查关键字参数。
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
# 使用示例：
#
#     # 返回 { x: 1, y: 2, z: 3 }
#     Meta::Utils::KeywordArgs.check(args: { x: 1, y: 2 }, schema: [:x, :y, { z: 3 }])
#
#     # 返回 { x: 1, y: 2, z: 4 }
#     Meta::Utils::KeywordArgs.check(args: { x: 1, y: 2, z: 4 }, schema: [:x, :y, { z: 3 }])
#
#     # Error: `x` is required
#     Meta::Utils::KeywordArgs.check(args: { y: 2, z: 3 }, schema: [:x, :y, { z: 3 }])
#
#     # Error: `a` is not allowed
#     Meta::Utils::KeywordArgs.check(args: { a: 1, y: 2, z: 3 }, schema: [:x, :y, { z: 3 }])

module Meta
  module Utils
    class KeywordArgs
      class << self
        def check(args:, schema:)
          schemas = build_schemas(schema)

          # 不接受额外的关键字参数
          extras = args.keys - schemas.keys
          raise "不接受额外的关键字参数：#{extras.join(', ')}" unless extras.empty?

          # 通过 schema 导出关键字参数
          missing = []
          result = schemas.map do |name, spec|
            if args.include?(name)
              [name, args[name]]
            elsif spec.include?(:default)
              [name, spec[:default]]
            else
              missing << name
            end
          end.to_h

          # 检查以上导出过程中是否找到缺失的参数
          if missing.empty?
            result
          else
            raise "缺失必要的关键字参数：#{missing.join(', ')}"
          end
        end

        private

          def build_schemas(spec)
            if spec.is_a?(Array)
              build_schemas_from_array(spec)
            elsif spec.is_a?(Hash)
              build_schemas_from_hash(spec)
            elsif spec.is_a?(Symbol)
              build_schemas_from_symbol(spec)
            else
              raise "未知的参数类型：#{spec.class}"
            end
          end

          def build_schemas_from_array(spec_array)
            spec_array.inject({}) do |accumulated, val|
              accumulated.merge!(build_schemas(val))
            end
          end

          def build_schemas_from_hash(spec_hash)
            spec_hash.transform_values do |val|
              { default: val }
            end
          end

          def build_schemas_from_symbol(spec_symbol)
            { spec_symbol => {} }
          end
      end
    end
  end
end
