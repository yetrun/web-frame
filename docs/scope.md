# scope 用法全揭秘

## 引言

### 解疑答惑：什么是场景化的字段

在实际开发中，我们经常会遇到这样的需求：在不同的场景下，返回不同的字段。以下是举例说明之的：

1. 在列表类的接口返回基本字段，而在详情类的接口返回更多的字段。
2. 在 `/admin` 下返回更多的字段，而在 `/user` 下返回更少的字段。
3. 用户有权限时返回更多的字段，而没有权限时返回更少的字段。而权限判断的过程是动态的。

Meta API 的 scope 功能就是为了解决这样的问题而设计的。

### 基本思想：将实体的所有字段写到同一个类中

这可以说是最基本的思想了，与传统的类的组合和继承的方式不同，我们将所有的字段都写到同一个类中。这样做的好处是，我们可以在一个地方看到所有的字段，而不必在多个类中查找。

### 传统的做法：使用类的组合和继承

如果我们有一个 `UserEntity` 类，它有若干字段。但考虑要用在不同的场景，我们需要定义不同的类。

首先，有些字段仅用于参数，有些字段仅用于返回。我们可以定义两个类：

```ruby
class UserParams < Grape::Entity
  expose :name
  expose :email
  expose :password
end

class UserEntity < Grape::Entity
  expose :id
  expose :name
  expose :email
end
```

编程的一个主要原则是 DRY（Don't Repeat Yourself），即不要有重复代码。以上的重复字段需要再增加一个类来实现：

```ruby
class UserFields < Grape::Entity
  expose :name
  expose :email
end

class UserParams < UserFields
  expose :password
end

class UserEntity < UserFields
  expose :id
end
```

这样，为实现参数和返回的字段分离，我们需要定义三个类。这样的做法不仅繁琐，而且不易维护。

这还没完，当涉及到不同的场景时，我们需要定义更多的类。例如，我们需要在 `/admin` 下返回更多的字段，那么我们需要继续定义 `AdminUserEntity` 类。这样，我们的类会越来越多，不易维护。

```ruby
class AdminUserParams < UserParams
  # 暴露一些特权参数
end

class AdminUserEntity < UserEntity
  # 返回一些特权字段
end
```

> 示例中用的是 Grape::Entity，Meta API 不支持这样的继承方式，因为内部的实现并不是如同 Grape::Entity 那样基于类的方式。

## 分场景使用 scope 举例

### 示例实体类

我们先定义一个实体类：

```ruby
class UserEntity < Meta::Entity
  property :id
  property :name
  property :email
  property :profile
  property :password
end
```

> 一般来讲，示例中用到的模型越简单越好，为了举例好几种不同场景下的 scope 用法，我们的模型定义也不能太过简单，比如只定义一个 `id` 字段。

### 区分参数和返回字段

如果字段仅用于返回值渲染，而不用于参数，我们可以用 `param: false` 定义；类似地，如果字段仅用于参数，而不用于返回值渲染，我们可以用 `render: false` 定义。

```ruby
class UserEntity < Meta::Entity
  property :id, param: false
  property :password, render: false
end
```

### 场景示例：列表接口和详情接口

属性可以定义 scope 选项，这相当于为属性声明可适用的场景，然后在引用实体时，使用 `lock_scope` 来限定声明可使用的场景。

假设列表类接口返回 `id`、`name` 这两个摘要性质的字段，而详情类接口返回 `profile` 这个更详细的字段，我们可以这样定义：

```ruby
class UserEntity < Meta::Entity
  property :id
  property :name
  property :profile, scope: 'detail'
end
```

在引用 `UserEntity` 时，默认只会返回 `id`、`name` 字段，而在引用 `UserEntity.lock_scope('detail')` 时，会返回 `id`、`name`、`profile` 字段。

```ruby
get '/users' do
  title '用户列表'
  status 200 do
    expose :users, type: 'array', ref: UserEntity
  end
end

get '/users/:id' do
  title '用户详情'
  status 200 do
    expose :user, ref: UserEntity.lock_scope('detail')
  end
end
```

### 场景示例：不同的接口锚点

在规划接口时，我们针对不同的平台可能设置不同的锚点。例如，针对管理端我们用 `/admin`，而针对用户端我们用 `/user`。我们同样可以只定义一个实体类，然后在引用时使用 `lock_scope` 来声明使用的场景。

```ruby
class UserEntity < Meta::Entity
  property :id
  property :name
  property :profile, scope: 'detail'
  property :email, scope: 'admin'
end
```

之前的接口我们可以认为是 `/user` 下的接口，而现在我们来定义 `/admin` 下的接口：

```ruby
namespace '/admin' do
  get '/users' do
    title '用户列表'
    status 200 do
      expose :users, type: 'array', ref: UserEntity.lock_scope('admin')
    end
  end

  get '/users/:id' do
    title '用户详情'
    status 200 do
      expose :user, ref: UserEntity.lock_scope(['detail', 'admin'])
    end
  end
end
```

上述定义中，`UserEntity.lock_scope('admin')` 会返回 `id`、`name`、`email` 字段，而 `UserEntity.lock_scope(['detail', 'admin'])` 会返回 `id`、`name`、`profile`、`email` 字段。

#### 在 `namespace` 层声明 scope

注意到上述两个接口都使用了 `UserEntity.lock_scope('admin')`。本着不接受重复的原则，我们可以将 `admin` scope 的声明放到 `namespace` 层：

```ruby
class UserEntity < Meta::Entity
  property :id
  property :name
  property :profile, scope: 'detail'
  property :email, scope: '$admin'
end

namespace '/admin' do
  meta do
    # 在整个 namespace 下都使用 '$admin' scope
    scope '$admin'
  end
  
  get '/users' do
    title '用户列表'
    status 200 do
      expose :users, type: 'array', ref: UserEntity
    end
  end

  get '/users/:id' do
    title '用户详情'
    status 200 do
      expose :user, ref: UserEntity.lock_scope('detail')
    end
  end
end
```

#### 全局 scope 和局部 scope

注意，`$admin` 需要添加 `$` 前缀，以区分普通的 scope.

默认情况下，`lock_scope` 是不会传递到下层的，例如下面的定义：

```ruby
class ProfileEntity < Meta::Entity
  property :id
  property :name
  property :brief, scope: 'detail'
end

class UserEntity < Meta::Entity
  property :id
  property :profile, scope: 'detail', ref: ProfileEntity
end
```

`UserEntity.lock_scope('detail')` 只会影响到 `UserEntity`，而不会影响到 `ProfileEntity`。它返回的是如下的结构：

```json
{
  "id": 1,
  "profile": {
    "id": 1,
    "name": "name"
  }
}
```

正确的做法是，在引用 `ProfileEntity` 时也使用 `lock_scope`：

```ruby
class UserEntity < Meta::Entity
  property :id
  property :profile, scope: 'detail', ref: ProfileEntity.lock_scope('detail')
end
```

## `with_common_options`：更有效的组织字段方式

在定义实体字段时，我们会依赖 scope 来组织字段。比如，相同的 scope 的字段会写在一起。使用 `with_common_options` 会减少我们的重复代码，不失为一种更有效的组织方式。

```ruby
class UserEntity < Meta::Entity
  property :id
  property :name
  
  with_common_options scope: 'detail' do
    property :profile
  end
  
  with_common_options scope: 'admin' do
    property :email
  end
end
```

由于我们更常见的是用 scope 来组织字段， 下面的写法更简洁（也更直观）：

```ruby
class UserEntity < Meta::Entity
  property :id
  property :name
  
  scope 'detail' do
    property :profile
  end
  
  scope 'admin' do
    property :email
  end
end
```

### `params` 和 `render` 也有同样的方式

参数和返回字段的组织方式也可以用 `with_common_options` 来实现。

```ruby
class UserEntity < Meta::Entity
  # 仅用于返回值渲染
  with_common_options param: false do
    property :id
  end

  # 仅用于参数
  with_common_options render: false do
    property :password
  end

  # 基本字段，任何情况下都会返回
  property :name
  
  # 详细字段，仅在详情类接口下才会返回
  with_common_options scope: 'detail' do
    property :profile
  end
  
  # 管理员字段，仅在管理员类接口下才会返回
  with_common_options scope: 'admin' do
    property :email
  end
end
```

或者，更简洁的写法：

```ruby
class UserEntity < Meta::Entity
  # 仅用于返回值渲染
  params do
    property :id
  end

  # 仅用于参数
  render do
    property :password
  end

  # 基本字段，任何情况下都会返回
  property :name
  
  # 详细字段，仅在详情类接口下才会返回
  scope 'detail' do
    property :profile
  end
  
  # 管理员字段，仅在管理员类接口下才会返回
  scope 'admin' do
    property :email
  end
end
```

## TODO

有关 $post、$put、$patch、$delete 的 scope 的说明。

一些常用的场景举例，例如如何实现仅针对字段的效果。

merge 用法。
