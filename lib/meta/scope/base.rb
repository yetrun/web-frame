# frozen_string_literal: true

module Meta
  class Scope
    module Errors
      class NameNotSet < StandardError; end
    end

    # 基本的 Scope 方法，引入该模块即可获取系列方法
    module Base
      def match?(scopes)
        scopes = [scopes] unless scopes.is_a?(Array)
        match_scopes?(scopes)
      end

      def match_scopes?(scopes)
        return true if @forwarded_scope&.match?(scopes)
        scopes.include?(self)
      end

      def defined_scopes
        [self]
      end

      def scope_name
        scope_name = @scope_name || self.name
        raise Errors::NameNotSet, '未设置 scope 名称' if scope_name.nil?

        scope_name.split('::').last
      end

      def scope_name=(name)
        @scope_name = name.to_s
      end

      def include_scope(*scopes)
        @forwarded_scope = Composite.concat(@forwarded_scope, *scopes)
      end

      # 既作为类方法，也作为实例方法
      def and(*scopes)
        scopes = [self, *scopes] if self != Meta::Scope
        And.new(*scopes)
      end
      alias_method :&, :and

      # 既可以是类方法，也可以是实例方法
      def or(*scopes)
        scopes = [self, *scopes] if self != Meta::Scope
        Or.new(*scopes)
      end
      alias_method :|, :or

      def inspect
        scope_name || super
      end
    end

    # 将 Scope 类的子类作为 Scope 实例
    class << self
      include Base

      def new(*args)
        raise NoMethodError, 'Meta::Scope 类不能实例化'
      end

      def inherited(subclass)
        # subclass.instance_variable_set(:@forwarded_scope, Or.new)

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

    # 组合式 Scope 实例，用于表示多个 Scope 的逻辑操作
    class Composite
      include Base

      def self.new(*scopes)
        if scopes.length == 0
          @empty || (@empty = self.new)
        elsif scopes.length == 1
          scopes[0]
        else
          super(*scopes)
        end
      end

      def self.concat(*scopes)
        composite_classes = scopes.filter { |scope| scope.is_a?(Composite) }
                                  .map(&:class).uniq
        raise ArgumentError, "不能执行 concat，参数中包含了多个逻辑运算符：#{composite_classes.join(',')}" if composite_classes.length > 1

        if composite_classes.empty?
          Or.new(*scopes)
        else
          composite_classes[0].new(*scopes)
        end
      end

      def initialize(*scopes)
        @scopes = scopes.compact.map do |scope|
          scope.is_a?(self.class) ? scope.defined_scopes : scope
        end.flatten.freeze
      end

      def defined_scopes
        @scopes
      end

      def scope_name
        @scope_name || @scopes.map(&:scope_name).sort.join('_')
      end
    end

    # 逻辑 And 操作
    class And < Composite
      # scopes 需要包含所有的 @scopes
      def match_scopes?(scopes)
        @scopes.all? { |scope| scope.match?(scopes) }
      end

      # 重定义 scope_name，如果用得上的话
      def scope_name
        @scope_name || @scopes.map(&:scope_name).sort.join('_and_')
      end
    end

    # 另一种 Scope 实例，用于表示多个 Scope 的逻辑 Or 操作
    class Or < Composite
      include Base

      # scopes 只需要包含一个 @scopes
      def match_scopes?(scopes)
        @scopes.any? { |scope| scope.match?(scopes) }
      end

      # 重定义 scope_name，如果用得上的话
      def scope_name
        @scope_name || @scopes.map(&:scope_name).sort.join('_or_')
      end
    end
  end
end
