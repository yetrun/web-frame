# frozen_string_literal: true

# 洋葱圈模型的链式调用，需要结合 Meta::RouteDSL::AroundActionBuilder 才可以看到它奇效。

module Meta
  class LinkedAction
    def initialize(current_proc, next_action)
      @current_proc = current_proc
      @next_action = next_action
    end

    def execute(execution)
      execution.instance_exec(@next_action, &@current_proc)
    end
  end
end
