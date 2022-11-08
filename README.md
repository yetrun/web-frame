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
  route('/api_spec', :get)
    .title('返回 API 规格文档')
    .do_any { 
      doc = Dain::SwaggerDocUtil.generate(NoteApp)
      response.body = [JSON.generate(doc)] 
    }

  route('/notes', :get)
    .title('查看笔记列表')
    .do_any {
      render('notes' => Note.all) 
    }
    .if_status(200) {
      expose :notes, type: 'array', using: NoteEntity
    }

  route('/notes', :post)
    .title('创建新的笔记')
    .params {
      param :note, type: 'object', using: NoteEntity
    }
    .do_any {
      note = Note.create!(params[:note])
      render({ 'note' => note }, { scope: 'full' })
    }
    .if_status(201) {
      expose :note, type: 'object', using: NoteEntity
    }

  route('/notes/:id', :get)
    .title('查看笔记')
    .params {
      param :id, type: 'integer'
    }
    .do_any {
      note = Note.find(params[:id])
      render({ 'note' => note }, { scope: 'full' })
    }
    .if_status(200) {
      expose :note, type: 'object', using: NoteEntity
    }

  route('/notes/:id', :put)
    .title('更新笔记')
    .params {
      param :note, type: 'object', using: NoteEntity
    }
    .do_any {
      note = Note.find(params[:id])
      note.update!(params[:note])
      render({ 'note' => note }, { scope: 'full' })
    }
    .if_status(200) {
      expose :note, type: 'object', using: NoteEntity
    }

  route('/notes/:id', :delete)
    .title('删除笔记')
    .do_any {
      note = Note.find(params[:id])
      note.destroy!
      note.status = 204
    }
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

### 将模块挂载在 Rack 下运行

API 模块同时也是一个 Rack 中间件，它可以挂载在 Rack 下运行：

```ruby
# config.ru

run NotesAPI
```

## 文档

- [使用教程](docs/使用教程.md)

## License

内测阶段，暂不开放。
