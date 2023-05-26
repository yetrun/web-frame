# frozen_string_literal: true

require_relative 'execution'
require_relative 'path_matching_mod'
require_relative 'metadata'

module Meta
  class Route
    include PathMatchingMod.new(path_method: :path, matching_mode: :full)

    attr_reader :path, :method, :meta, :action

    def initialize(path: '', method: :all, meta: {}, action: nil)
      @path = Utils::Path.normalize_path(path)
      @method = method
      @meta = Metadata.new(meta)
      @action = action
    end

    def execute(execution, remaining_path)
      path_matching.merge_path_params(remaining_path, execution.request)

      execution.parse_parameters(@meta[:parameters]) if @meta[:parameters]
      execution.parse_request_body(@meta[:request_body]) if @meta[:request_body]

      action.execute(execution) if action

      render_entity(execution) if @meta[:responses]
    rescue Execution::Abort
      nil
    end

    def match?(execution, remaining_path)
      request = execution.request
      remaining_path = '' if remaining_path == '/'
      method = request.request_method

      return false unless path_matching.match?(remaining_path)
      return false unless @method == :all || @method.to_s.upcase == method
      return true
    end

    private

    def render_entity(execution)
      responses = @meta[:responses]
      status = execution.response.status
      codes = responses.keys
      return unless codes.include?(status)

      entity_schema = responses[status]
      execution.render_entity(entity_schema) if entity_schema
    end
  end
end
