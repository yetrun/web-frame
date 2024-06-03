# frozen_string_literal: true

module Meta
  module JsonSchema
    module Scopes
      # 一个基本的 ScopeMatcher
      class BasicMatcher
        attr_reader :name

        def initialize(name)
          @name = name
        end

        def match?(scopes)
          scopes.include?(self)
        end

        def defined_scopes
          [self]
        end

        def inspect
          @name
        end
      end

      # 能够继承其他 Scope 的 ScopeMatcher
      class ExtendsMatcher < BasicMatcher
        attr_reader :name, :parent

        def initialize(parents, name: nil)
          @name = name
          @forward = OrMatcher.new(parents)
        end

        def match?(scopes)
          return true if @forward.match?(scopes)
          super
        end
      end

      # And 操作符
      class AndMatcher
        def initialize(scopes)
          @scopes = scopes
        end

        def match?(scopes)
          @scopes.all? { |scope| scope.match?(scopes) }
        end

        def name
            @scopes.map(&:name).join('__')
        end

        def inspect
          @scopes.map(&:inspect).join(' & ')
        end
      end

      # Or 操作符
      class OrMatcher
        def initialize(scopes)
          @scopes = scopes
        end

        def match?(scopes)
          @scopes.any? { |scope| scope.match?(scopes) }
        end

        def defined_scopes
          @scopes.flat_map(&:defined_scopes).uniq
        end

        def inspect
          @scopes.map(&:inspect).join(' | ')
        end
      end

      module Utils
        class << self
          # 帮助实体解析名称，这里主要是考虑 scope 的作用
          #
          # base_schema_name: 具有 Params 或 Entity 后缀的基础名称
          # user_scopes: 用户传进来的 scope 数组
          # candidate_scopes: 从实体中找出的能够参与命名的备选的 scope 数组
          def resolve_name(base_schema_name, user_scopes, candidate_scopes)
            # 从备选的 scope 中获取到被利用到的
            scopes = candidate_scopes.filter { |candidate_scope| candidate_scope.match?(user_scopes) }
            scope_names = scopes.map(&:name)

            # 合成新的名字
            schema_name_parts = [base_schema_name] + scope_names
            schema_name_parts.join('__')
          end
        end
      end

      module Factory
        class << self
          def new(name)
            BasicMatcher.new(name)
          end

          def extends(*parents, name: nil)
            ExtendsMatcher.new(parents, name: name)
          end

          def and(*scopes)
            AndMatcher.new(scopes)
          end

          def or(*scopes)
            OrMatcher.new(scopes)
          end
        end
      end
    end
  end
end
