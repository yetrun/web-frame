# 更新日志

## 0.2.0（2024 年 6 月 28 日）

1. 自定义参数类型：可以在 ObjectSchemaBuilder 内使用自定义类作为参数类型。
2. 添加 `within` 语法，它返回一个只包含指定字段的实体，类似于 `include`.
3. query 参数支持 `type: 'array'` 类型，它使用的是我们熟悉的 formData 格式。
4. 修复 `with_common_options` 方法中使用 `render` 简写格式的 bug。

## 0.1.2（2024 年 6 月 5 日）

1. 实现新的基于常量的 Scope 场景化模式。
2. 属性的 `scope:` 选项如果传递的是字符串数组，则恢复为 `或` 模式。
3. 取消 HTTP method 自动生成对应的 Scope常量。
4. 修复 `locked(discard_missing: true)` 时生成文档报错。
5. 属性新增 `enum:` 选项，`allowable:` 作为其别名存在。

## 0.1.1（2024 年 6 月 1 日）

1. 添加 `Meta::Entity.with_common_options` 方法，用于更有效地组织字段。
2. 临时性地添加 `Meta::Entity.merge` 方法，作为合并其他的实体的暂时性实现。
3. scope 分为全局 scope 和局部 scope.

## 0.1.0（2023 年 8 月 5 日）

1. 删除 `on:` 选项。
2. `type_conversion` 为 `false` 时不影响对象和数组类型的转化。
3. 修复 `ref:` 嵌套造成的文档问题。
4. 将 HTTP Method 的 scope 添加 `$` 符号前缀，如 `$get`、`$post` 等。
5. `Meta.config` 去掉了 `default_locked_scope` 的配置项。

## 0.0.9（2023 年 7 月 22 日）

1. JsonSchema 添加 before:、after: 选项，用于在过滤前后执行一些操作。
2. 新添加一个 if: 选项用在属性上，它能够作为一个条件，当条件为 false 时，该属性不会被包含在结果内。
3. 属性的 scope: 选项改名为 on: 选项。
4. MetaBuilder 添加一个 scope 宏。
5. Meta.config 的 JsonSchema 相关配置项改名。
6. 优化异常的捕获。

## 0.0.8（2023 年 7 月 17 日）

1. `Meta.config` 添加 `initialize_configuration` 方法，用于接受若干个 Hash 初始化配置。
2. 修复 GET 请求下会将 `header` 参数覆盖为 `query` 参数的 bug.

## 0.0.7（2023 年 7 月 14 日）

1. 定义 parameters 宏时能够自动识别 `path` 参数。
2. 定义 params 宏时能够自动识别 `GET` 路由，此时参数的 `in` 默认为 `query`.
3. JsonSchema: `default:` 选项可以是一个块。
4. 有且只有一个 `status` 宏定义时，不需要显示地设置 `response.status`.
5. `Meta.config` 添加一个新的选析 `default_locked_scope`，借助它可以设置一个默认的 `locked_scope` 值。
6. `JsonSchema` 的 `filter` 方法添加一个新的选项 `extra_properties:`，当设定值为 `:ignore` 时可以允许额外的属性。
7. 添加新的选项 `config.json_schema_user_options`、`config.json_schema_param_stage_options`、`config.json_schema_render_stage_options`. 借助这三个选项可以对 `JsonSchema#filter` 方法的选项进行设置。同时废弃了 `render_type_conversion`、`render_validation` 等零散的选项。
8. `meta` 宏的父级、子级的合并规则调整：parameters、params、responses 都有所合并。

## 0.0.6（2023 年 5 月 26 日）

1. 添加了 Meta::Execution#abort_execution! 方法。
2. 重新规范响应体的 application/json 设定，尽可能不过分设定。
3. 修复了若干实现上和文档的 bug.

## 0.0.5（2023 年 4 月 27 日）

1. 调整了 `around` 钩子的执行顺序，它与 `before` 钩子共同定义顺序。
2. 修复了若干 bug.

## 0.0.4（2023 年 4 月 18 日）

1. `Application` 添加 `.around` 宏。
2. `render` 时支持传递 `user_data` 选项，用作 value 解析的第二个参数。

## 0.0.3（2023 年 4 月 4 日）

1. 添加两个新的选项 `ref:` 和 `dynamic_ref:`，以便后期取代 `using:`.
2. 提供 Rails 插件。

## 0.0.2（2023 年 3 月 8 日）

1. 添加两个配置项，适合生产环境下使用，用以关闭渲染时的数据验证验证。
2. 添加对多态实体的支持。
