# Dain 框架

Dain 框架是一个适用于 Web API 的后端框架，采用 Ruby 语言编写。它最大的特色在于实现即文档的思想。

## 安装

在 Gemfile 中添加：

```ruby
gem 'dain', git: 'https://github.com/yetrun/web-frame'
```

## 快速上手

### 定义 API

通过继承 `Dain::Application` 来定义一个 API 模块。（PS：以下示例的运行依赖 `ActiveRecord`）

```ruby
require 'dain'

class NotesAPI < Dain::Application
  get '/notes' do
    title '查看笔记列表'
    status 200 do
      expose :notes, type: 'array', using: NoteEntity
    end
    action do
      render :notes, Note.all
    end
  end

  post '/notes' do
    title '创建新的笔记'
    params do
      param :note, type: 'object', using: NoteEntity
    end
    status 201 do
      expose :note, type: 'object', using: NoteEntity
    end
    action do
      note = Note.create!(params[:note])
      response.status = 201
      render :note, note, scope: 'full'
    end
  end

  get '/notes/:id' do
    title '查看笔记'
    params do
      param :id, type: 'integer'
    end
    status 200 do
      expose :note, type: 'object', using: NoteEntity
    end
    action do
      note = Note.find(params[:id])
      render :note, note, scope: 'full'
    end
  end

  put '/notes/:id' do
    title '更新笔记'
    params do
      param :note, type: 'object', using: NoteEntity
    end
    status 200 do
      expose :note, type: 'object', using: NoteEntity
    end
    action do
      note = Note.find(params[:id])
      note.update!(params[:note])
      render :note, note, scope: 'full'
    end
  end

  delete '/notes/:id' do
    title '删除笔记'
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
class NoteEntity < Dain::Entity
  property :id, type: 'integer', param: false
  property :title, type: 'string'
  property :content, type: 'string', render: { scope: 'full' }
end
```

我们发现了一些特殊的定义：

- 标记 `id` 的 `param` 选项为 `false`，它不作为参数传递。

- 标记 `content` 在 `render` 下的 `scope`，当且仅当显示传递 `scope` 为 `false` 时才会渲染此字段。（对比 *查看笔记列表* 和 *查看笔记* 接口）

### 生成 API 文档

通过主动调用以下的方法可以生成 OpenAPI 的规格文档（JSON 文档）：

```ruby
NoteAPI.to_swagger_doc
```

### 将模块挂载在 Rack 下运行

API 模块同时也是一个 Rack 中间件，它可以挂载在 Rack 下运行：

```ruby
# config.ru

run NotesAPI
```

## 文档

- [教程](docs/教程.md)
- [索引](docs/索引.md)

## License

LGPL v2
