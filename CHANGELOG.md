# CHANGE LOG

## 拆分 parameters 和 requestBody

params 遗留方法，作为它们的合并宏

## 添加 info 选项

app.to_swagger_doc(info: { title: '...' })

## 使用 $ref 引用实体

- [x] 为 Entity 添加一个 schema_name 方法，它将文档转化为 `$ref: '...'` 的形式。
- [x] 尚未区分参数和返回值。
- [x] 文档注释关键点：schemas，匿名类不受到影响。

## 重构嵌套路由的逻辑

1. 添加了 `namespace` 宏，它与 Application 基本表现一致
2. `apply` 方法接受 `tags` 选项
3. 删除链式语法中 `route.nesting` 的使用

## 在描述性语法中支持 meta 宏定义

既可以使用

```ruby
meta do
  title 'xxx'
  tags ['xxx']
  description 'xxx'
  params do ... end
  status 200 do ... end
end
```

也可以使用

```ruby
title 'xxx'
tags ['xxx']
description 'xxx'
params do ... end
status 200 do ... end
```

## 使用描述性语法替代链式语法

旧的链式语法形如：

```ruby
route('/articles/:id', :put)
  .title('更新一篇新的文章')
  .params {
    param :article, using: ArticleEntity
  }
  .resource { Article.find(params[:id]) }
  .authorize { resource.author == @current_user }
  .do_any {
    resource.update!(params[:article])
  }
  .if_status(200) {
    expose :article, using: ArticleEntity
  }
```

然而新的描述性语法形如

```ruby
route('/articles/:id', :post) do
  title '更新一篇新的文章'
  params do
    param :article, using: ArticleEntity
  end
  status(200) do
    expose :article, using: ArticleEntity
  end
  action do
    article = Article.find(params[:id])
    authorize article, :update
    article.update!(params[:article])
  end
end
```

仔细感受一下它们的区别。

## 为 Dain::Entity 添加一个 locked 方法
```ruby
# 在 using 时调用 scope 方法
params do
  param :article, using: ArticleEntity.locked(scope: 'xxx', exclude: [:hidden])
end
```

## 为 Dain::Entity 添加一个 lock_exclude 方法

```ruby
# 如下定义一个 Entity
class ArticleEntity < Dain::Entity
  param :title, type: 'string'
  param :content, type: 'string'
  param :hidden, type: 'boolean'
end

# 在 using 时调用 scope 方法
params do
  param :article, using: ArticleEntity.lock_exclude([:hidden])
end
```

以上设置后，参数解析时会自动消除掉 `hidden` 参数。

## 为 Dain::Entity 添加一个 lock_scope 方法

```ruby
# 如下定义一个 Entity
class ArticleEntity < Dain::Entity
  param :title, type: 'string', scope: 'normal'
  param :content, type: 'string', scope: 'normal'
  param :hidden, type: 'boolean', scope: 'super'
end

# 在 using 时调用 scope 方法
params do
  param :article, using: ArticleEntity.lock_scope('normal')
end
```

以上设置后，参数解析时会自动应用 `scope: 'normal' 规则`. 注意，即使在调用时手动传递了 `scope` 选项也不会参考。
