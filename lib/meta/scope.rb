# frozen_string_literal: true

module Meta
  class Scope
    module Errors
      class NameNotSet < StandardError; end
    end

    # 基本的 Scope 方法，引入该模块即可获取系列方法
    module ScopeMethods
      def match?(scopes)
        scopes = [scopes] unless scopes.is_a?(Array)

        return true if @included_scopes.any? { |super_scope| super_scope.match?(scopes) }
        scopes.include?(self)
      end

      def defined_scopes
        [self]
      end

      def scope_name
        scope_name = @scope_name || self.name
        raise Errors::NameNotSet, '未设置 scope 名称' if scope_name.nil?

        scope_name
      end

      def scope_name=(name)
        @scope_name = name
      end

      def include_scope(*scopes)
        @included_scopes += scopes
      end

      # 既作为类方法，也作为实例方法
      def and(*scopes)
        scopes = [self, *scopes] if self != Meta::Scope
        And.new(*scopes)
      end
      alias_method :&, :and

      def or(*scopes)
        scopes = [self, *scopes] if self != Meta::Scope
        Or.new(*scopes)
      end
      alias_method :|, :or
    end

    # 将 Scope 类的子类作为 Scope 实例
    class << self
      include ScopeMethods

      def inherited(subclass)
        subclass.instance_variable_set(:@included_scopes, [])

        # 如果是 Meta::Scope 的具体子类被继承，该子类加入到 @included_scopes 原语中
        subclass.include_scope(self) if self != Meta::Scope
      end

      def include(*mods)
        scopes = mods.filter { |m| m < Meta::Scope }
        mods = mods - scopes

        include_scope(*scopes) if scopes.any?
        super(*mods) if mods.any?
      end
    end

    # 另一种 Scope 实例，用于表示多个 Scope 的逻辑 And 操作
    class And
      include ScopeMethods

      def initialize(*scopes)
        @scopes = scopes.freeze
      end

      def match?(scopes)
        scopes = [scopes] unless scopes.is_a?(Array)

        # scopes 需要包含所有的 @scopes
        @scopes.all? { |scope| scopes.include?(scope) }
      end

      def defined_scopes
        @scopes
      end

      def scope_name
        @scope_name || @scopes.map(&:scope_name).sort.join('_and_')
      end
    end

    # 另一种 Scope 实例，用于表示多个 Scope 的逻辑 Or 操作
    class Or
      include ScopeMethods

      def initialize(*scopes)
        @scopes = scopes.freeze
      end

      def match?(scopes)
        scopes = [scopes] unless scopes.is_a?(Array)

        # scopes 只需要包含一个 @scopes
        @scopes.any? { |scope| scopes.include?(scope) }
      end

      def defined_scopes
        @scopes
      end

      def scope_name
        @scope_name || @scopes.map(&:scope_name).sort.join('__')
      end
    end
  end
end
