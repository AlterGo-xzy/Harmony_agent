# harmony_agent MCP Agent Adapter 集成说明

`@harmony_agent/agent-connectors` 是无页面 HAR。它把现有 `@harmony_agent/mcp-client` 的 Server Profile、Tool 和调用结果映射到 Agent 公共 Tool 契约，不提供任务提交、确认、记录或界面接口。任务控制仍只通过 `AgentRuntimeFacade`。

## 装配边界

宿主或后续 M09-B 生产装配按以下顺序连接：

1. 创建一个 `ConnectorDigestPort`。生产实现必须返回稳定的密码学摘要；测试可以注入确定性 fixture。
2. 用同一个 digest port 创建 `McpInvocationPolicyBridge`。
3. 创建 `McpClientManager` 时把该 bridge 作为 `McpManagerOptions.invocationPolicy`；不要为 Agent MCP 调用注册允许全部请求的 policy。
4. 用 `McpClientManagerToolPort` 包装 manager。Adapter 每个 invocation 只调用一次 `callTool`，不在该层重试。
5. 向 `McpProviderRegistry` 注册实际交给 manager 的 Server Profile 和受控版本。Profile 的 endpoint、协议或超时配置变化会生成新的 profile digest。
6. 向 `McpReadOnlyToolPolicyRegistry` 注册明确允许的只读工具。远端 annotations 不决定 risk、side effect、权限或数据边界；未进入本地 allowlist 的工具不会进入 Agent Tool Registry。
7. 注入 `McpGrantVerifierPort`。它必须校验完整 `ToolInvocation` 与 M02 grant 的 task、step、operation、tool identity、schema 和 arguments 绑定。由于 `RuntimeCoordinator` 已在 dispatch 前消费一次 grant，同一 invocation 的 `IDEMPOTENT_REPLAY` 可以作为允许结果；不同 invocation 的复用必须拒绝。没有 verifier 的默认放行实现。
8. 调用 `refreshCatalog()`，把返回的 `ToolRegistryEntry` 写入 `agent_runtime.ToolRegistry`。Provider/Profile 或 schema 变化会改变 `registryVersion` 和 Registry snapshot；`invalidatedToolIds` 用于清除外部 Router cache。旧 grant 携带的 identity/schema 会在调用前失败。
9. 把 `McpStepDispatchAdapter` 作为 M03 `StepDispatchPort` 注入内部 Runtime 装配。异步完成通过 `McpToolOutcomeSinkPort` 回送给 Runtime 的 completion 通道；它不是第二个任务控制入口。

真实网络宿主需要在自己的 HAP `module.json5` 中声明 `ohos.permission.INTERNET`；HAR 本身不拥有宿主权限或 Ability 生命周期。

## 调用与失败语义

- MCP 身份始终包含 `{serverId, kind, name}`，Tool ID 形如 `mcp://<serverId>/tool/<name>`。
- schema 使用规范 JSON 后计算组合 digest；tool identity 还绑定 profile digest。
- 参数会重新规范化并核对授权时的 arguments digest，随后校验 M02 grant，再签发一次性 MCP policy ticket。
- MCP policy ticket 只允许一次匹配的 Server、Tool 和参数调用；未装配 ticket 时 manager fail-closed。
- Adapter 不重试工具调用。查询、目录缓存和查询重试继续由现有 MCP client 管理。
- 当前 M06 registry 仅接收受控只读工具，强制 `SideEffect.NONE`。写工具及断线后的未知结果/对账留给对应后续任务，不得用只读 policy 绕过。
- MCP `NETWORK`、`TIMEOUT`、`AUTHENTICATION`、`FORBIDDEN`、`POLICY_DENIED`、`CANCELLED` 和配置错误会映射到 Agent error taxonomy。

## 验收边界

M06 的 HAR 构建和 adapter contract test 证明纯映射、授权桥、一次调用和 M03 dispatch port 接线。它们不等于产品 HAP、真实远端 MCP、设备网络、M09-B 生产 Facade 装配或 S2 真实任务闭环；这些场景必须使用各自的运行证据关闭。
