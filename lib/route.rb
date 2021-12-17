require_relative 'env'

class Route
  def initialize
    @blocks = []
  end

  def do_any(&block)
    @blocks << block

    return self
  end

  def resource(&block)
    # 这个块是在 env 环境下执行的
    p = Proc.new {
      resource = block.call
      # 为 env 添加一个 resource 方法
      define_singleton_method(:resource) { resource }
    }
    @blocks << p

    return self
  end

  def call
    # 首先，要初始化一个执行环境
    env = Env.new

    # 然后，依次执行这个执行环境
    @blocks.each do |b|
      env.instance_eval &b
    end

    # 最后，返回这个 env
    env
  end
end
