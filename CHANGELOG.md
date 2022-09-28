# CHANGE LOG

## 为 Dain::Entities::Entity 添加一个 lock_exclude 方法

```ruby
# 如下定义一个 Entity
class ArticleEntity < Dain::Entities::Entity
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

## 为 Dain::Entities::Entity 添加一个 lock_scope 方法

```ruby
# 如下定义一个 Entity
class ArticleEntity < Dain::Entities::Entity
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
