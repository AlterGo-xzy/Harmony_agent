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

2026-10-13 的只读查询确认已安装 `aigw.exe`，配置中已有一个完整且已选中的 Profile，并提供默认 alias `aigw/default`。

仓库提供 `tools/test-local-ai-gateway.ps1` 作为受控真实 smoke probe。它只能由 `aigw run --client ...` 注入 loopback base URL 和当前用户 runtime token；脚本拒绝工作区外输出，不打印或持久化 token，也不保存原始 Provider 响应或错误 message，只记录 `/ready`、chat HTTP 状态、固定回复是否匹配、finish reason、token usage，以及失败时可选的 `error.code`/`error.type`。运行该 probe 会启动已安装网关并发起一次真实上游模型请求，必须单独授权；完成后的进程停止也必须包含在同一授权范围内。

三次真实 smoke 已于 2026-10-13 逐次授权执行。三次 `/ready` 均返回 200，说明已安装 Runtime、受管 token 注入、本地认证及活动配置加载成功。原上游模型 `deepseek-v4-flash` 的两次 `POST /v1/chat/completions` 均返回 404，第二次脱敏诊断只提取到 Provider `error.code="404"`，`error.type` 缺失。随后在无密钥 revision 6 备份保护下临时改用 `deepseek-flash`；该请求返回 403，`error.code="403"`、`error.type` 缺失，说明 Provider 对新模型名的处理不同，但当前账号权限或 Provider 策略仍拒绝完成。三次都没有保存错误 message 或原始响应。网关 usage 累计记录 3 次失败，输入、输出和总 token 均为 0。三次 finally stop 均成功，最终复核 `running=false` 且端口 4000 无监听。

无凭据的独立路由检查中，配置上游的 `/v1/models` 与 `/v1/chat/completions` 均返回 401，证明域名和 API 路径存在。网关源码核对确认请求进入 public endpoint 后先校验 alias，再由生成的 LiteLLM 配置把 `aigw/default` 映射到 Provider 专用上游模型；public alias 不会原样发送给上游。现有脱敏证据把故障范围收敛到 Token Hub 的模型目录、账号权限或 Provider 策略。真实 Provider 门仍未关闭；下一步需要配置所有者确认该账号实际可用的模型 ID，任何再次计费请求都应单独授权。

候选模型验证失败后的自动回滚暴露了已安装网关的配置写入问题：第一次 `model update` 成功生成 revision 7 与 `config.json.bak`，此后的三次官方 CLI 回滚均返回 `aigw_config_io`。文件独占句柄检查排除了残留进程锁；只读源码检查显示 `ConfigurationStore` 使用 `File.Replace`，仅在 `UnauthorizedAccessException` 时进入备用原子移动路径，本机 EFS 配置文件触发的 `IOException` 不会回退。最终以已验证 SHA-256 的网关自动备份交换恢复 revision 6/`deepseek-v4-flash`，revision 7/`deepseek-flash` 同时保留为自动备份和工作区证据。该恢复没有读取凭据或再次访问 Provider。修复网关保存逻辑前，不应依赖连续 `model update` 自动回滚。

2026-10-13 16:00 的更新后只读核对确认：安装版本为 unsigned development `0.1.1-dev+b7fbc52`，活动配置已变为 revision 11，完整 Profile `deepseek` 通过 OpenAI-compatible Provider `https://api.deepseek.com` 把 `aigw/default` 映射到 `deepseek-flash`。Runtime 当时正在运行，doctor healthy、target circuit closed、连续失败为 0；该检查明确标记 `modelProbePerformed=false`、`upstreamContacted=false`，因此只是新配置预检。安装提交相对先前核对的源码只改动 `README.md` 和 `scripts/package.ps1`，没有改变 Runtime 或 `ConfigurationStore`，上段 `IOException` 回退缺口仍然存在。

同日 22:45 经单次明确授权执行更新后真实 smoke。执行前真实配置为 revision 12，Profile `deepseek` 完整且活动，`aigw/default` 仍映射到官方 Provider 的 `deepseek-flash`。探针取得 `/ready` 200 与 `/v1/chat/completions` 200；usage 前后差值为 1 次成功、42 input tokens、24 output tokens、66 total tokens，证明受管 runtime token、本地认证、alias 路由和官方 DeepSeek 请求链路已实际工作。模型输出在 `max_tokens=24` 处以 `finish_reason=length` 结束，固定文本未完全匹配，因此严格内容断言保持失败，未自动重试。证据不含 credential、原始响应或错误正文；网关在 finally 中停止，postcheck 确认恢复到执行前的 `running=false`。该结果仍不证明 HarmonyOS 设备 loopback、设备网络、真实取消/timeout 资源释放或 S6 benchmark。
