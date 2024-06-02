# frozen_string_literal: true

module Meta
  module JsonSchema
    class ScopeMatcher
      attr_reader :defined_scopes

      def initialize(query_clause)
        query_clause = [query_clause] if query_clause.is_a?(String) || query_clause.is_a?(Symbol)
        query_clause = { all_of: query_clause } if query_clause.is_a?(Array)

        @match_type, @defined_scopes = query_clause.first
      end

      def match?(providing_scopes)
        # 目前认为空数组就是不做 scope 筛选
        return false if providing_scopes.empty?

        case @match_type
        when :some_of
          # 只要相交就可以
          (@defined_scopes & providing_scopes).any?
        when :all_of
          # @defined_scopes 一定要被包含在 providing_scopes 内
          (@defined_scopes - providing_scopes).empty?
        else
          raise "Unknown match type: #{@match_type}"
        end
      end
    end
  end
end
