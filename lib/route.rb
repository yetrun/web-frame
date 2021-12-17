# 每个块都是在 execution 环境下执行的

require_relative 'execution'

class Route
  def initialize
    @blocks = []
  end

  def do_any(&block)
    @blocks << block

    return self
  end

  def param(name)
    do_any {
      unless request_body
        request_io = rack_env['rack.input']
        self.request_body = JSON.parse(request_io.read)
      end

      params[name.to_sym] = request_body[name.to_s]
    }
  end

  def resource(&block)
    do_any {
      resource = block.call
      # 为 execution 添加一个 resource 方法
      define_singleton_method(:resource) { resource }
    }
  end

  def authorize(&block)
    do_any {
      permitted = instance_eval(&block)
      unless permitted
        self.body = 'Not permitted!'
        raise Execution::Abort.new
      end
    }
  end

  def call(rack_env)
    # 首先，要初始化一个执行环境
    execution = Execution.new(rack_env)

    # 然后，依次执行这个执行环境
    begin
      @blocks.each do |b|
        execution.instance_eval &b
      end
    rescue Execution::Abort
      execution
    end

    # 最后，返回这个 execution
    execution
  end
end
