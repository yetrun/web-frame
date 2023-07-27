# frozen_string_literal: true

require_relative 'execution'
require_relative 'path_matching_mod'
require_relative 'metadata'

module Meta
  class Route
    include PathMatchingMod.new(path_method: :path, matching_mode: :full)

    attr_reader :path, :method, :meta, :action

    # path 是局部 path，不包含由父级定义的前缀
    def initialize(path: '', method: :all, meta: {}, action: nil)
      @path = Utils::Path.normalize_path(path)
      @method = method
      @meta = Metadata.new(meta)
      @action = action
    end

    def execute(execution, remaining_path)
      path_matching.merge_path_params(remaining_path, execution.request)

      execution.route_meta = @meta # 解析参数的准备
      action.execute(execution) if action
      @meta.set_response(execution) if @meta.responses
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

    def generate_operation_doc(schemas)
      meta.generate_operation_doc(schemas, scope: ["$#{method}"])
    end
  end
end
