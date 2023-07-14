# frozen_string_literal: true

module Meta
  module Utils
    class KeywordArgs
      module Checker
        class << self
          # 将 options 内的值修正为固定值，该方法会原地修改 options 选项。
          # 如果 options 中的缺失相应的值，则使用 fixed_values 中的值补充；如果 options 中的值不等于 fixed_values 中对应的值，则抛出异常。
          # 示例：
          # （1）fix!({}, { a: 1, b: 2 }) # => { a: 1, b: 2 }
          # （2）fix!({ a: 1 }, { a: 2 }) # raise error
          def fix!(options, fixed_values)
            fixed_values.each do |key, value|
              if options.include?(key)
                if options[key] != value
                  raise ArgumentError, "关键字参数 #{key} 的值不正确，必须为 #{value}"
                end
              else
                options[key] = value
              end
            end
            options
          end

          def merge_defaults!(options, defaults)
            defaults.each do |key, value|
              options[key] = value unless options[key]
            end
            options
          end
        end
      end
    end
  end
end
