# frozen_string_literal: true

module Meta
  module JsonSchema
    class ScopeMatcher
      def initialize(query_clause)
        query_clause = [query_clause] if query_clause.is_a?(String) || query_clause.is_a?(Symbol)
        query_clause = { some_of: query_clause } if query_clause.is_a?(Array)

        @match_type, @scopes = query_clause.first
      end

      def match?(scopes)
        return false if scopes.empty?

        case @match_type
        when :some_of
          (@scopes & scopes).any?
        when :all_of
          (@scopes - scopes).empty?
        else
          raise "Unknown match type: #{@match_type}"
        end
      end
    end
  end
end
