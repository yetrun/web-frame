# frozen_string_literal: true

require_relative '../support/schema_options'

module Meta
  module JsonSchema
    # 表示一个基本类型的 Schema，或继承自该类表示一个拥有其他扩展能力的 Schema.
    #
    # 该类包含了通用 JsonSchema 思维的基本逻辑，比如 stage 和 scope. 其他 Schema 类应当主动地继
    # 承自该类，这样就会自动获得 stage 和 scope 的能力。
    #
    # 该类剩余的逻辑是提供一个 `options` 属性，用于描述该 Schema. 因此，直接实例化该类可以用于表示
    # 基本类型，而继承该类可以用于表示还有内部递归处理的对象和数组类型。这时，应当在子类的构造函数中调
    # 用父类的构造方法，以便初始化 `options` 属性。并且在子类中重写 `filter_internal` 方法，实现
    # 内部递归处理的逻辑。这种模式的案例主要是 `ObjectSchema` 和 `ArraySchema`.
    #
    # 如果是组合模式，也应当继承自该类，以便获得 stage 和 scope 的能力。但是，组合模式的 `options`
    # 调用是非法的，因此不应当在构造函数中调用父类的构造方法。此时 options 为 nil，这样用到 options
    # 的地方都会抛出异常（NoMethodError: undefined method `[]' for nil:NilClass）。这种模式
    # 的案例很多，包括 StagingSchema、RefSchema 等。
    class BaseSchema
      # `options` 包含了转换器、验证器、文档、选项。
      #
      # 由于本对象可继承，基于不同的继承可分别表示基本类型、对象和数组，所以该属
      # 性可用在不同类型的对象上。需要时刻留意的是，无论是用在哪种类型的对象内，
      # `options` 属性都是描述该对象的本身，而不是深层的属性。
      #
      # 较常出现错误的是数组，`options` 是描述数组的，而不是描述数组内部元素的。
      attr_reader :options

      def initialize(options = {})
        raise ArgumentError, 'options 必须是 Hash 类型' unless options.is_a?(Hash)
        @options = SchemaOptions::BaseBuildOptions.check(options)
      end

      def filter?
        true
      end

      def filter(value, user_options = {})
        user_options = SchemaOptions::UserOptions::Filter.check(user_options)

        value = value_callback(user_options) if options[:value]
        value = before_callback(value, user_options) if options[:before]
        value = JsonSchema::Presenters.present(options[:presenter], value) if options[:presenter]
        value = resolve_default_value(options[:default]) if value.nil? && options.key?(:default)
        value = options[:convert].call(value) if options[:convert]

        # 第一步，转化值。
        # 需要注意的是，对象也可能被转换，因为并没有深层次的结构被声明。
        type = options[:type]
        unless user_options[:type_conversion] == false || type.nil? || value.nil?
          begin
            value = JsonSchema::TypeConverter.convert_value(value, type)
          rescue JsonSchema::TypeConvertError => e
            raise JsonSchema::ValidationError.new(e.message)
          end
        end

        # 第二步，做校验。
        validate!(value, options) unless user_options[:validation] == false

        # 第三步，如果存在内部属性，递归调用。
        value = filter_internal(value, user_options) unless value.nil?

        # 最后，返回 value
        value = after_callback(value, user_options) if options[:after]
        value
      end

      # 返回能够处理 scope 和 stage 的 schema（可以是 self），否则应返回 UnsupportedStageSchema 或 nil.
      def find_schema(stage:, scope:)
        staged(stage)&.scoped(scope)
      end

      # 返回能够处理 stage 的 schema（可以是 self），否则返回 UnsupportedStageSchema.
      def staged(stage)
        self
      end

      # 返回能够处理 scope 的 schema（可以是 self），否则返回 nil.
      def scoped(scope)
        self
      end

      # defined_scopes_mapping 是一个 Hash，用于缓存已经计算出的 scopes，用于避免重复计算。其主要针对的是具有命名系统的 Schema，如 Meta::Entity
      def defined_scopes(stage:, defined_scopes_mapping:)
        []
      end

      # 执行 if: 选项，返回 true 或 false
      def if?(object_value, execution = nil)
        if_block = options[:if]
        return true if if_block.nil?

        args_length = if_block.lambda? ? if_block.arity : 1
        args = args_length > 0 ? [object_value] : []
        if execution
          execution.instance_exec(*args, &options[:if])
        else
          options[:if]&.call(*args)
        end
      end

      def value?
        options[:value] != nil
      end

      # 生成 Swagger 文档的 schema 格式。
      #
      # 选项：
      # - stage: 传递 :param 或 :render
      # - schema_docs_mapping: 用于保存已经生成的 Schema
      # - defined_scopes_mapping: 用于缓存已经定义的 scopes
      # - presenter: 兼容 Grape 框架的实体类
      def to_schema_doc(**user_options)
        return Presenters.to_schema_doc(options[:presenter], options) if options[:presenter]

        schema = {}
        schema[:type] = options[:type] if options[:type]
        schema[:description] = options[:description] if options[:description]
        schema[:enum] = options[:enum] if options[:enum]

        schema
      end

      def to_schema
        self
      end

      private

      def validate!(value, stage_options)
        stage_options.each do |key, option|
          validator = JsonSchema::Validators[key]
          validator&.call(value, option, stage_options)
        end
      end

      def resolve_value(value, user_options, value_proc, arguments)
        if value_proc.lambda?
          value_proc_params = arguments[0...value_proc.arity]
        else
          value_proc_params = arguments
        end
        if user_options[:execution]
          user_options[:execution].instance_exec(*value_proc_params, &value_proc)
        else
          value_proc.call(*value_proc_params)
        end
      end

      def resolve_default_value(default_resolver)
        if default_resolver.respond_to?(:call)
          default_resolver.call
        elsif default_resolver.respond_to?(:dup)
          default_resolver.dup
        else
          default_resolver
        end
      end

      def filter_internal(value, user_options)
        value
      end

      def value_callback(user_options)
        resolve_value(nil, user_options, options[:value], [user_options[:object_value], user_options[:user_data]])
      end

      def before_callback(value, user_options)
        resolve_value(value, user_options, options[:before], [value, user_options[:object_value], user_options[:user_data]])
      end

      def after_callback(value, user_options)
        resolve_value(value, user_options, options[:after], [value, user_options[:object_value], user_options[:user_data]])
      end
    end
  end
end
