# scope

据知情人士透漏，框架的 scope 很难用。为打破这种难用的印象，我需要做一个完整的教程。

## 传统的做法：使用类的组合和继承

如果我们有一个 `UserEntity` 类，它有若干字段。但考虑要用在不同的场景，我们需要定义不同的类。

首先，有些字段仅用于参数，有些字段仅用于返回。我们可以定义两个类：

```ruby
class UserParams < Grape::Entity
  expose :name
  expose :email
  expose :age
  expose :password
end

class UserEntity < Grape::Entity
  expose :id
  expose :name
  expose :email
  expose :age
end
```

编程的一个主要原则是 DRY（Don't Repeat Yourself），即不要有重复代码。以上的重复字段需要再增加一个类来实现：

```ruby
class UserFields < Grape::Entity
  expose :name
  expose :email
  expose :age
end

class UserParams < UserFields
  expose :password
end

class UserEntity < UserFields
  expose :id
end
```

这样，为实现参数和返回的字段分离，我们需要定义三个类。这样的做法不仅繁琐，而且不易维护。

### 这还没完

当涉及到不同的场景时，我们需要定义更多的类。例如，我们需要在 `/admin` 下返回更多的字段，那么我们需要定义 `AdminUserEntity` 类。这样，我们的类会越来越多，不易维护。

```ruby
class AdminUserParams < UserParams
  # 暴露一些特权参数
end

class AdminUserEntity < UserEntity
  # 返回一些特权字段
end
```

## 更好的做法：使用 scope

为了解决上述问题，我们可以使用 scope。我们可以定义一个 `UserEntity` 类，然后使用 lock_scope 来限定使用的字段。

```ruby
class UserEntity < Meta::Entity
  property :id, param: false # 使用 param: false 来禁止作为参数
  property :name
  property :email
  property :age
  property :password, render: false # 使用 render: false 来禁止渲染
  
  property :field1, scope: 'admin' # 特权字段使用 scope 来限定
  property :field2, scope: 'admin'
end
```

`param: false` 和 `render: false` 为我们解决了参数和返回字段的区分问题。而 `scope` 则为我们解决了不同场景下的字段问题。

在引用实体时，我们可以使用 `lock_scope` 来限定使用的字段，例如 `UserEntity.lock_scope('admin')`。这样引用的实体才会包含 `field1` 和 `field2` 字段。我们再一次来梳理一下：

```ruby
class UserEntity < Meta::Entity
  # 仅用于返回
  property :id, param: false
  
  # 以下字段总是会使用
  property :name
  property :email
  property :age

  # 仅用于参数
  property :password, render: false
  
  # 仅在引用时传递了 'admin' scope 时才会使用，例如 UserEntity.lock_scope('admin')
  property :field1, scope: 'admin'
  property :field2, scope: 'admin'
end
```

### 自由组合的乐趣

scope 的组合是非常的灵活的。我们现在抽象一点，在场景 A 下，我们希望返回 `x`、`y` 字段，而在场景 B 下，我们希望返回 `y`、`z` 字段。我们可以这样定义：

```ruby
class UserEntity < Meta::Entity
  property :x, scope: 'A'
  property :y, scope: ['A', 'B']
  property :z, scope: 'B'
end
```

我们只需要引用为 `UserEntity.lock_scope('A')` 或 `UserEntity.lock_scope('B')` 即可。 属性的 `scope` 选项可以理解为支持的场景列表。当 `lock_scope` 的参数和属性的 `scope` 选项有交集时，该属性就会被使用。

如果换成类的组合或继承，我们需要定义两个类：

```ruby
class A < Grape::Entity
  expose :x
  expose :y
end

class B < Grape::Entity
  expose :y
  expose :z
end
```

哦天呐，字段 `y` 重复了，我们还需要定义一个公共类：

```ruby
class Both_A_and_B < Grape::Entity
  expose :y
end

class A < Both_A_and_B
  expose :x
end

class B < Both_A_and_B
  expose :z
end
```

最终我们需要三个类来达到效果，这还只是我构想的最为简单的场景了。

### 自由组合的另一个乐趣

对于下面的实体定义：

```ruby
class UserEntity < Meta::Entity
  property :x, scope: 'A'
  property :y, scope: 'B'
  property :z, scope: 'C'
end
```

我们可以使用 `UserEntity.lock_scope(['A', 'B'])` 来引用 `x` 和 `y` 字段。排除掉无意义的空组合，实际上有七种组合方式：

- `UserEntity.lock_scope('A')`
- `UserEntity.lock_scope('B')`
- `UserEntity.lock_scope('C')`
- `UserEntity.lock_scope(['A', 'B'])`
- `UserEntity.lock_scope(['A', 'C'])`
- `UserEntity.lock_scope(['B', 'C'])`
- `UserEntity.lock_scope(['A', 'B', 'C'])`

我们只用写在一个类里，然后就可以实现出组合七种的引用模式了。这在单纯使用类的方式下是极其繁琐的。

## 在更高层次上中声明 scope

如果频繁地去写 `lock_scope`，也是有点繁琐的。现在我们可以在 namespace 和 route 中定义 scope，定义的 scope 会自动传递到下面的层次中，这样就可以不必写 `lock_scope` 了，这样可以在一定程度上减轻工作。

```ruby
namespace '/admin' do
  meta do
    scope 'admin'
  end
  
  get '/user' do
    status 200, UserEntity
  end
end
```

这样，`UserEntity` 就会自动继承 `admin` scope，不必再写 `UserEntity.lock_scope('admin')` 了。实际上，它等价于

```ruby
namespace '/admin' do
  get '/user' do
    status 200, UserEntity.lock_scope('admin')
  end
end
```

试想下，如果使用类的组合或继承的模式，将会多么繁琐。

## `with_common_optins`：有节奏的组合方式

在每个属性后面添加 `scope` 可能是让人不能接受的方式。例如下面这种：

```ruby
class UserEntity < Meta::Entity
  # 以下定义基础字段
  property :id
  property :name
  property :email
  property :age
  
  # 以下定义特权字段
  property :field1, scope: 'admin'
  property :field2, scope: 'admin'
end
```

在有节奏的字段组织里，`scope` 相同的字段可能会被放在一起。我们可以使用 `with_common_options` 来简化这个过程：

```ruby
class UserEntity < Meta::Entity
  # 以下定义基础字段
  property :id
  property :name
  property :email
  property :age

  # 以下定义特权字段
  with_common_options scope: 'admin' do
    property :field1
    property :field2
  end
end
```

或者更进一步：

```ruby
class UserEntity < Meta::Entity
  # 以下定义基础字段
  property :id
  property :name
  property :email
  property :age

  # 以下定义特权字段
  scope 'admin' do
    property :field1
    property :field2
  end
end
```

这样简洁的表达方式可能更直观些。

## 最后再来谈谈为什么会有类的组合和继承这种方式

因为对于一般开发者而言更熟悉，毕竟这是已经掌握了数年的技术。而 scope 这种方式是相对新的，需要一定的学习成本。但是，一旦掌握了 scope 的使用，会发现它的强大之处。

## TODO

有关 $post、$put、$patch、$delete 的 scope 的说明。

一些常用的场景举例，例如如何实现仅针对字段的效果。

merge 用法。
