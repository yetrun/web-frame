# 为 Rails 项目带来参数验证效果

Gemfile 中引入框架的新版本：

```ruby
gem 'meta-api'
```

在 `application_controller.rb` 下加入：

```ruby
require 'meta/json_schema/rails'

class ApplicationController < ActionController::API
  include Meta::JsonSchema::Rails::Plugin

  rescue_from Meta::JsonSchema::ValidationErrors do |e|
    render json: e.errors, status: :bad_request
  end
end
```

即可在控制器下开通参数验证效果。示例：

```ruby
class UsersController < ApplicationController
  params do
    param :user, required: true do
      param :name, type: 'string', default: 'Jim'
      param :age, type: 'integer', default: 18
    end
  end
  def create
    p params     # params 会被修改为验证后的参数
    p raw_params # 原生的参数被保留到 raw_params 方法中
  end
end
```

详细语法规则参见[教程](教程.md)。
