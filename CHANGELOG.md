# 更新日志

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
