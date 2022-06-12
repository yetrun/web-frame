# frozen_string_literal: true

module JsonSchema
  module TypeConverter
    @type_converters = {
      { 'string' => 'boolean' } => lambda do |value|
        unless %w[true True TRUE false False FALSE].include?(value)
          raise JsonSchema::TypeConvertError.new('string', 'boolean')
        end

        value.downcase == 'true'
      end,
      { 'string' => 'integer' } => lambda do |value|
        # 允许的格式：+34、-34、34、34.0 等
        raise JsonSchema::TypeConvertError.new('string', 'integer') unless value =~ /^[+-]?\d+(\.0+)?$/

        value.to_i
      end,
      { 'string' => 'float' } => lambda do |value|
        raise JsonSchema::TypeConvertError.new('string', 'float') unless value =~ /^[+-]?\d+(\.\d+)?$/

        float = value.to_f
        float.to_i == float ? float.to_i : float
      end,
      { %w[boolean integer float] => 'string' } => lambda do |value|
        value.to_s
      end,
      { 'float' => 'integer' } => lambda do |value|
        raise JsonSchema::TypeConvertError.new('float', 'integer') unless value.to_i == value

        value.to_i
      end,
      { 'integer' => 'float' } => lambda do |value|
        value.to_f
      end,
      { 'object' => 'string' } => lambda do |value|
        # 包括解析出如日期等类型
        value.to_s
      end
    }
    @type_resolvers = {
      [TrueClass, FalseClass] => 'boolean',
      [Integer] => 'integer',
      [Float] => 'float',
      [String] => 'string',
      [Array] => 'array',
      [Object] => 'object'
    }

    class << self
      def convert_value(value, target_type)
        return nil if value.nil? # 不转化 null 值

        # 首先尝试转化类型
        value_type = resolve_type(value)
        value = convert_value_to_type(value, value_type, target_type) if value_type != target_type

        # 需要检查类型是否匹配
        match_type!(value, target_type)

        value
      end

      private

      def convert_value_to_type(value, source_type, target_type)
        type_converter = resolve_type_converter(source_type, target_type)
        type_converter ? type_converter.call(value) : value
      end

      def match_type!(value, target_type)
        is_known_type = @type_resolvers.values.include?(target_type)
        raise JsonSchema::UnknownType.new(target_type) unless is_known_type

        value_type = resolve_type(value)
        raise JsonSchema::TypeConvertError.new(value_type, target_type) unless value_type == target_type
      end

      def resolve_type(value)
        @type_resolvers.each do |classes, type|
          return type if classes.any? { |klass| value.is_a?(klass) }
        end
      end

      def resolve_type_converter(source_type, target_type)
        @type_converters.each do |mapping, converter|
          source_types_mapping, target_type_mapping = mapping.first
          source_types_mapping = [source_types_mapping] unless source_types_mapping.is_a?(Array)
          return converter if source_types_mapping.include?(source_type) && target_type_mapping == target_type
        end

        nil
      end
    end
  end

  class TypeConvertError < StandardError
    def initialize(source_type, target_type)
      super("类型转化出现错误，期望是一个 `#{target_type}`，但得到的是一个 `#{source_type}`")
    end
  end

  class UnknownType < StandardError
    def initialize(target_type)
      super("未知的目标类型 `#{target_type}`")
    end
  end
end
