# frozen_string_literal: true

require_relative 'base'

# 兼容以前的字符串 scope
module Meta
  class Scope
    module Utils
      class << self
        # 根据选项构建 Scope 实例，这是兼容之前的字符串写法。
        def parse(scope)
          scope = [scope] if scope.is_a?(String) || scope.is_a?(Symbol)

          # 只会有两种类型：Array[String] 和 Scope 子类
          if scope.is_a?(Meta::Scope::Base)
            scope
          elsif scope.is_a?(Array)
            scopes = scope.map { |s| parse_string(s) }
            Or.new(*scopes)
          else
            raise ArgumentError, 'scope 参数必须是一个数组或者 Scope 子类'
          end
        end

        def and(*scopes)
          scopes = scopes.map { |s| parse(s) }
          And.new(*scopes)
        end

        private

          def parse_string(str)
            # 确保全局存在一个 Scopes 模块
            unless defined?(::Scopes)
              scopes = Module.new
              Object.const_set(:Scopes, scopes)
            end

            # 获取类名化的 scope 名称
            scope_name = str.to_s.split('_').map(&:capitalize).join

            # 如果 Scopes 模块中已经存在该 scope 类，直接返回
            return ::Scopes.const_get(scope_name) if ::Scopes.const_defined?(scope_name)

            # 如果不存在，创建一个新的类
            scope_class = Class.new(Meta::Scope)
            scope_class.scope_name = str
            ::Scopes.const_set(scope_name, scope_class)

            # 返回结果
            scope_class
          end
      end
    end
  end
end