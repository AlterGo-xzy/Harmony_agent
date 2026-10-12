# Provider Connector 集成说明

`@harmony_agent/agent-connectors` 0.3.0 在同一 HAR 中提供 M06 MCP adapter、M07 LLM/Remote API connector，以及 Local AI Gateway 的具体 Model transport。它是 `agent_runtime` 的可注入依赖，不是新的任务控制入口；外部产品仍只通过 `AgentRuntimeFacade` 提交和控制任务。网关装配见 [LOCAL_AI_GATEWAY_INTEGRATION.md](LOCAL_AI_GATEWAY_INTEGRATION.md)。

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

## 当前验收边界

M07 的 15 项 contract test 使用 fake credential、timer 和 transport，验证 DTO、追溯、费用、fail-closed、取消与未知结果语义。Local AI Gateway transport 另有 5 项主机协议 fixture；与 M06 合并运行时为 33/33。它们不证明真实上游 Provider、设备网络、生产 credential store 或 Runtime 端到端装配。具体 transport 仍需独立补充真实取消/timeout 资源释放和设备网络验收证据。
