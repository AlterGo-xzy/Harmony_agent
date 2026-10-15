# Provider Connector 集成说明

`@harmony_agent/agent-connectors` 0.4.0 在同一 HAR 中提供 M06 MCP adapter、M07 LLM/Remote API connector、Local AI Gateway 的具体 Model transport，以及把 `ModelProvider` 适配到既有 `SemanticPlannerPort` 的 `ProviderSemanticPlanner`。它是 `agent_runtime` 的可注入依赖，不是新的任务控制入口；外部产品仍只通过 `AgentRuntimeFacade` 提交和控制任务。网关装配见 [LOCAL_AI_GATEWAY_INTEGRATION.md](LOCAL_AI_GATEWAY_INTEGRATION.md)。

## 组合边界

宿主或后续 M09-B composition root 负责提供：

- `ProviderCredentialPort`：按 `providerId + credentialScope` 从受保护存储解析短期凭据；
- `ModelTransportPort`、`EmbeddingTransportPort`、`RemoteApiTransportPort`：实现具体 Provider 的 HTTP/SDK 映射和底层网络取消；
- `ProviderTimerPort`：生产环境可使用 `SystemProviderTimer`，测试可注入确定性计时器；
- `ProviderGrantVerifierPort`：把 Remote API `ToolInvocation` 重新绑定到 M02 已签发且仍有效的内部 grant；
- `ConnectorDigestPort` 与 `ConnectorClockPort`：沿用 Runtime 的摘要和时钟实现。

Provider 专用 model ID 只保存在 `ModelProviderProfile.providerModelId`，调用 Runtime 使用稳定的 `registryModelId`。`ProviderCatalog` 绑定 provider、capability version、region 和 `ProviderPriceSnapshot`，返回隔离副本，避免注册后的输入对象或调用方修改当前快照。

## 调用与追溯

模型和 Embedding 请求必须携带选路时冻结的 model version、region 与 price snapshot ID。成功结果返回同一组 trace 字段和 `ProviderUsage`；connector 使用冻结价格计算 `settledCostMicros`，同时保留 Provider 报告的成本。

Remote API 返回 `RemoteApiProviderResult`。其中 `outcome` 是通用 `ToolOutcome`，外层同时记录 provider、capability version、region、price snapshot 和 usage。参数 JSON 在调用前规范化并核对摘要，随后验证 grant；任一步骤失败都会在解析凭据和启动网络前关闭。

## 凭据与资源生命周期

普通 invocation、workflow、stream chunk、结果和错误不包含认证 header。`ProviderOperationRunner` 只在输入和取消预检通过后调用 `ProviderCredentialPort`，再把凭据直接交给 transport。transport 不应把凭据复制到请求 DTO、日志、trace 或 provider receipt。

取消或 timeout 会调用当前 `ProviderOperationHandle.cancel()`，取消计时器并解除取消订阅。transport 的 `cancel()` 必须关闭或中止实际 HTTP/SDK 资源。对于已经启动且带副作用的 Remote API，网络中断、取消或 timeout 返回 `UNKNOWN_OUTCOME`；connector 不自动重试，后续由恢复与对账流程处理。

## Semantic Planner 适配

`createProviderMcpProductionAgentRuntime` 与恢复型工厂接收一个已注册的 `RegisteredModelProvider`、匹配的 `ModelProvider` 和 Planner 配置，并使用 `ProductionAgentRuntimePorts` 中同一组 Runtime 时钟与 ID 生成器构造 `ProviderSemanticPlanner`。调用方不得预置另一 Planner；缺 clock 或 ID 时会在 MCP 目录发现前失败。构造完成后仍复用既有 catalog-before-Facade 边界，外部只获得唯一 `AgentRuntimeFacade`。

Provider 只能返回受约束的 JSON 草图。Adapter 会重新生成 workflow/clarification 的可信 task、workflow、version、时间和 ID 字段，随后检查步骤字段、JSON schema、依赖与 entry、DAG、binding、Tool capability，以及副作用与幂等关系。ready、clarificationRequired 与 rejected 的 payload 必须互斥；身份/usage 不一致、非 `stop` 结束、额外字段或非法图都返回稳定拒绝码。输入/输出 token 和金额按任务预算严格比较，0 表示没有可用额度。Provider Promise 异常保留为异常边界，由 T32 Runtime 统一闭合为脱敏的 `plannerInvocationFailed`。

可选 observer 只接收 phase、task ID、Provider request ID、Provider/model/version/region/price、finish reason、planning status、稳定拒绝码和 usage。它不接收 prompt、模型输出、凭据或用户回答；observer 异常不能影响规划结果。

## 当前验收边界

M07 的 15 项 contract test 使用 fake credential、timer 和 transport；Local AI Gateway transport 有 5 项主机协议 fixture；T33 Provider Semantic Planner 有 6 项；T34 production composition 增加 3 项。与 M06/M09-B MCP 用例合并运行时为 47/47。T34 的无签名隔离 Release HAR 为 56,551 bytes、SHA-256 `05AE633E28D6326F9B07124911B3FC7F84C7DF3A9A20450613F434DF1AB0831C`。

这些主机门不证明真实 Provider Planner 请求、生产凭据存储、真实取消/timeout、HAP/设备行为或 S6 system run。已有 Local AI Gateway 和 MCP 设备证据仍按各自版本与验收范围独立记录，不能替代 T34 的真实 Provider Planner 系统证据。
