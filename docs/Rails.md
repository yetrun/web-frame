# 作为 Rails 插件

## 安装

首先，你需要将其安装在 Rails 项目中：

```ruby
gem 'meta-api'
```

在 config/initializers 目录下创建一个文件，例如 `meta_rails_plugin.rb`，并写入：

```ruby
require 'meta/rails'

Meta::Rails.setup
```

在 `application_controller.rb` 下加入：

```ruby
class ApplicationController < ActionController::API
  # 引入插件，同时引入 route 宏、params_on_schema 方法、json_on_schema 渲染器
  include Meta::Rails::Plugin

  # 处理参数验证错误
  rescue_from Meta::Errors::ParameterInvalid do |e|
    render json: e.errors, status: :bad_request
  end
end
```

这样，一切就准备好了。

## 示例

接口定义：

```ruby
class UsersController < ApplicationController
  route '/users', :post do
    params do
      param :user, required: true do
        param :name, type: 'string'
        param :age, type: 'integer'
      end
    end
  end
  def create
    user = User.create!(params_on_schema[:user])
    render json_on_schema: user
  end
end
```

生成 Swagger 文档：

```ruby
Rails.application.eager_load! # 需要提前加载所有常量
Meta::Rails::Plugin.generate_swagger_doc(ApplicationController)
```
