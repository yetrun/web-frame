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

      set_status(execution)
      render_entity(execution) if @meta[:responses]
    rescue Execution::Abort
      execution.response.status = 200 if execution.response.status == 0
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

    def set_status(execution)
      response_definitions = @meta[:responses]
      response = execution.response
      if response.status == 0
        response.status = (response_definitions&.length > 0) ? response_definitions.keys[0] : 200
      end
    end

    def render_entity(execution)
      response_definitions = @meta[:responses]
      return if response_definitions.empty? # 未设定 status 宏时不需要执行 render_entity 方法

      # 查找 entity schema
      entity_schema = response_definitions[execution.response.status]
      return if entity_schema.nil?

      # 执行面向 schema 的渲染
      execution.render_entity(entity_schema)
    end
  end
end
