# Local AI Gateway 集成说明

`@harmony_agent/agent-connectors` 0.3.0 提供 `LocalAIGatewayModelTransport`，把 M07 的通用 `ModelTransportPort` 映射到 Local AI Gateway 的 OpenAI-compatible `POST /v1/chat/completions`。该适配只承担 Provider 网络协议，不创建、提交或控制任务；外部调用方仍只能通过 `AgentRuntimeFacade` 控制 Agent。

## 已核对的网关契约

2026-10-12 对 `C:\claude-gateway` 的只读核对基于 `codex/develop`、commit `21017a1e91a1`。网关公开监听基址为 `http://127.0.0.1:4000`，模型入口包括 `/v1/chat/completions`、`/v1/responses` 和 `/v1/messages`，健康入口为 `/health` 与 `/ready`。本适配选择 `/v1/chat/completions`，默认公共 alias 为 `aigw/default`。

每次请求必须提供一个本地网关 token。本适配接受 `Authorization: Bearer ...` 或 `x-api-key` 中的一种，并拒绝空值、同时提供两种认证方式或附带其他 credential header。token 必须由宿主实现的 `ProviderCredentialPort` 在调用时解析；不能写入源码、Profile、任务 DTO、日志、报告或快照。

## 宿主装配

宿主先创建 transport profile，并把它和同一时点冻结的价格快照注册进 `ProviderCatalog`：

```ets
const gateway: LocalAIGatewayTransportProfile = new LocalAIGatewayTransportProfile();
gateway.modelVersion = activeGatewayProfileRevision;
gateway.maxInputTokens = 32768;
gateway.maxOutputTokens = 4096;
gateway.qualityTier = 1;
gateway.privacyClasses = [PrivacyClass.PUBLIC, PrivacyClass.PERSONAL];
gateway.available = readyAtSnapshotTime;

const modelProfile: ModelProviderProfile = createLocalAIGatewayModelProfile(gateway);
const catalog: ProviderCatalog = new ProviderCatalog(digestPort);
if (!catalog.registerModel(modelProfile, priceSnapshot)) {
  throw new Error('Local AI Gateway model snapshot is invalid');
}
const registered: RegisteredModelProvider =
  catalog.getModel(gateway.registryModelId) as RegisteredModelProvider;
const provider: GenericModelProvider = new GenericModelProvider(
  registered,
  new LocalAIGatewayModelTransport(gateway, new ArkTsLocalAIGatewayHttpClient()),
  new ProviderOperationRunner(credentialPort, new SystemProviderTimer())
);
```

`priceSnapshot.providerId` 必须等于 `local-ai-gateway`，`capabilityId` 必须等于 `aigw/default`，`capabilityVersion` 与 `gateway.modelVersion` 相同，region 与 `local-windows` 相同。价格应反映活动网关 Profile 实际路由的上游成本；不能用测试用零价格代替生产快照。

Runtime-facing 请求继续使用稳定的 `model.local.gateway`。`GenericModelProvider` 在 transport 边界把它转换为 Provider alias `aigw/default`，冻结 model version、region、price snapshot，并统一结算 usage/cost。JSON object schema 会映射为 `response_format.json_schema`；空 object schema 不发送 `response_format`。当前实现使用单次非流式响应，收到完整结果后向 observer 发送一个规范化 chunk。

## 网络和权限

`ArkTsLocalAIGatewayHttpClient` 使用 `@ohos.net.http`，最终产品宿主必须声明 `ohos.permission.INTERNET`。HAR 自身不能授予权限。

默认地址仅允许 `http://127.0.0.1:<port>/v1` 或 `http://localhost:<port>/v1`，并校验端口范围。它适用于与网关处于同一网络命名空间的宿主。HarmonyOS 设备或模拟器中的 `127.0.0.1` 指向设备自身，不会自动到达 Windows 主机；设备验收必须另行建立并记录明确的端口转发或受控桥接，验证 `/ready`、认证调用、取消/timeout 和清理。

## 当前证据边界

SDK 原生 Previewer/Hypium 已运行 `agent_connectors` 33/33，其中新增 5 项覆盖 profile/loopback 校验、chat 请求与结构化响应、两种认证方式及脱敏、HTTP 状态映射、usage 完整性和取消委托。Release HAR 为 42,015 bytes、SHA-256 `F2C510AA59377A466D59CDC7B890668DDC15A2AE3FCA7F61720A0A872C66A051`。该门使用内存 HTTP fixture，证明协议映射和安全边界，不证明 Windows 网关进程、活动 Profile、真实上游 Provider、设备网络或生产 credential store。

2026-10-13 的只读查询确认已安装 `aigw.exe`，配置中已有一个完整且已选中的 Profile，并提供默认 alias `aigw/default`；Runtime 尚未加载它，状态为 `running=false`、`activeProfileId=null`，端口 4000 无监听。因此本次没有启动网关、读取 token 或发起真实 Provider 请求；这些动作需要独立运行验收。
