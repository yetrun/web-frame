# Meta 框架

Meta 框架是一个用于开发 Web API 的后端框架，采用 Ruby 语言编写。正如它的名字，它是用定义“元”信息的方式实现 API，同时生成一份符合 Open API 规格的接口文档。

> 有关框架名称的由来，阅读[框架的名称由来](docs/名称由来.md)。

## 脚手架

可直接使用我的[脚手架](https://github.com/yetrun/web-frame-example)项目上手体验：

```bash
$ git clone https://github.com/yetrun/web-frame-example.git
```

## 安装

在 Gemfile 中添加：

```ruby
gem 'meta-api', '~> 0.0.8' # Meta 框架处于快速开发阶段，引入时应尽量固定版本
```

然后在 Ruby 代码中引用：

```ruby
require 'meta/api'
```

> 或者可嵌入到 Rails 项目中使用，参考[为 Rails 项目带来参数验证效果](docs/Rails.md)。

## 快速一览

### 定义 API

通过继承 `Meta::Application` 来定义一个 API 模块。（PS：以下示例的运行依赖 `ActiveRecord`）

```ruby
class NotesAPI < Meta::Application
  get '/notes' do
    title '查看笔记列表'
    status 200 do
      expose :notes, type: 'array', ref: NoteEntity
    end
    action do
      render :notes, Note.all
    end
  end

  post '/notes' do
    title '创建新的笔记'
    params do
      param :note, type: 'object', ref: NoteEntity
    end
    status 201 do
      expose :note, type: 'object', ref: NoteEntity.lock_scope('full')
    end
    action do
      note = Note.create!(params[:note])
      response.status = 201
      render :note, note
    end
  end

  get '/notes/:id' do
    title '查看笔记'
    params do
      param :id, type: 'integer'
    end
    status 200 do
      expose :note, type: 'object', ref: NoteEntity.lock_scope('full')
    end
    action do
      note = Note.find(params[:id])
      render :note, note, scope: 'full'
    end
  end

  put '/notes/:id' do
    title '更新笔记'
    params do
      param :note, type: 'object', ref: NoteEntity
    end
    status 200 do
      expose :note, type: 'object', ref: NoteEntity.lock_scope('full')
    end
    action do
      note = Note.find(params[:id])
      note.update!(params[:note])
      render :note, note, scope: 'full'
    end
  end

  delete '/notes/:id' do
    title '删除笔记'
    status 204
    action do
      note = Note.find(params[:id])
      note.destroy!
      response.status = 204
    end
  end
end
```

### 定义实体

以上示例看到有用到 `NoteEntity`，它是一个预先定义的实体：

```ruby
class NoteEntity < Meta::Entity
  property :id, type: 'integer', param: false # 不作为参数传递
  property :title, type: 'string'
  property :content, type: 'string', render: { scope: 'full' } # 列表页接口不返回此字段
end
```

### 生成 API 文档

通过主动调用以下的方法可以生成 Open API 的规格文档：

```ruby
NotesAPI.to_swagger_doc
```

该 Open API 文档是 JSON 格式，可以在 Swagger UI 下预览效果。如果也不乐意自己搭建 Swagger UI，可以直接使用在线的：

> http://openapi.yet.run/playground

### 将模块挂载在 Rack 下运行

API 模块同时也是一个 Rack 中间件，它可以挂载在 Rack 下运行。假设以上文件分别位于 `notes_api.rb` 和 `note_entity.rb`，在项目下新建文件 `config.ru`，并写入：

```ruby
require 'meta/api'
require_relative 'notes_api'
require_relative 'note_entity'

# 将文档挂载到 /api_spec 锚点下
map '/api_spec' do
  run ->(env) { 
    [200, { 'CONTENT_TYPE' => 'application/json' }, [JSON.generate(NotesAPI.to_swagger_doc)]]
    }
end

# 启动 NotesAPI 中定义的接口
run NotesAPI
```

然后执行命令：`bundle exec rackup`，接口即可启动。

## 文档

- [教程](docs/教程.md)
- [索引](docs/索引.md)

## 支持

你可以通过以下途径获得支持：

1. 通过 GitHub 提交 [ISSUE](https://github.com/yetrun/web-frame/issues)
2. 通过 QQ 群（489579810）获得实时答疑
3. 对本项目提交 [Pull Request](https://github.com/yetrun/web-frame/pulls)

## License

LGPL-2.1
