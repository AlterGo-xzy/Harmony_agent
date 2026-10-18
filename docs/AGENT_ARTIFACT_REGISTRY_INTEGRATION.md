# harmony_agent Artifact Registry 集成说明

T46 提供无 UI 的 Artifact Registry 与 durable Storage adapter。它是策略发布数据面，不是第二个任务控制入口；产品宿主仍只能通过 `AgentRuntimeFacade` 提交和控制任务。

## 1. 信任边界

1. 离线发布流程使用 T45 `offline/artifact_tooling/artifact-tool.mjs verify`，以宿主信任的 Ed25519 公钥、expected key ID 和完整 package bytes 验证 canonical package。
2. 生产 `ArtifactPackageVerifierPort` 必须把 `packageDigest + manifest.signedManifestDigest + signingKeyId` 绑定到上述真实验签结果和当前撤销策略。不能只看 manifest 中的 `signatureAlgorithm` 或 `signatureBase64` 就返回 `true`。
3. `ArtifactRegistryDigestPort` 必须提供密码学摘要，用于 Registry snapshot integrity。测试中的字符串 digest 只用于协议测试。
4. `ArtifactRuntimeEnvironment` 由宿主按实际 HAR/runtime、设备 API 和已实现 feature schema 构造。当前 evaluator 只接受明确的 `harmony_agent-runtime>=x.y.z` 与 `api>=n`；未知约束 fail-closed。

生产密钥生成、私钥保护、轮换和撤销不在 HAR 中实现。私钥不得进入设备包、Registry snapshot、事件或日志。

## 2. Storage 接线

宿主先按既有恢复流程打开 `DurableExecutionRecoveryStore`，再创建 adapter：

```ts
const persistence = new DurableArtifactRegistryAdapter(durableExecutionStore);
const opened = await ArtifactRegistry.open(
  runtimeEnvironment,
  trustedPackageVerifier,
  persistence,
  cryptographicRegistryDigest
);
if (!opened.accepted || opened.registry === undefined) {
  throw new Error('artifact registry failed closed');
}
const artifactRegistry = opened.registry;
```

`DurableArtifactRegistryAdapter` 使用固定 record ID `artifact-registry:m11`。它复用 execution store 的隔离副本与 backend CAS，因此 Registry 变更只有在完整 durable snapshot 成功后才对当前进程可见。CAS 冲突后不要继续发布或执行策略；重开 durable store 与 Registry，读取获胜版本后再决策。

若宿主需要独立数据库，仍可自行实现 `ArtifactRegistryPersistencePort`，但必须保持相同的 compare-and-set、完整性和先持久化后发布语义。

## 3. 生命周期

每个 artifact ID 表示一个不可漂移的 provenance/payload identity。生命周期更新可以改变审批、签名和 rollback metadata，但不能改写 source commit、lineage、feature schema、runtime compatibility、payload digest 或三类结果表。

允许的路径沿用公共契约：

```text
disabled -> shadow
shadow -> canary | disabled
canary -> active | shadow | rolledBack
active -> rolledBack
rolledBack -> disabled
```

- `shadow` 不参与选择，可以未签名；T47 runner 只记录有界观察，绝不采用 shadow decision。
- `canary`、`active`、`rolledBack` 必须通过 `ArtifactPackageVerifierPort` 和实际 Runtime compatibility 检查。
- 每种 `ArtifactKind` 同时最多一个 canary 指针和一个 active 指针。
- canary 晋升 active 时，以一次 CAS 替换 active 指针并清空 canary。
- active rollback manifest 必须指向 Registry 中同 kind、已验签且仍保留的历史 active digest；成功后以一次 CAS 恢复该指针。
- 调用 `activeArtifact`/`canaryArtifact` 只读取 defensive copy，不会提交或推进任务。

T47 的 `ArtifactPolicyReleaseRunner` 已把这些指针接入通用发布 harness：每次先获得有效 baseline；shadow 仅观察；命中 canary bucket 时才尝试 canary；canary 失败先回退当前 active，active 失败再回退 baseline。Runner 只接受候选 ID 和 opaque JSON，不替代具体 Router 的资格过滤、预算或授权。生产 policy loader、超时/取消和 M12–M14 learned policy 接线仍由后续模块负责。

## 4. 验收边界

T46 主机验收覆盖：

- Runtime manifest/compatibility/verifier fail-closed；
- disabled、shadow、canary、active 和 digest rollback；
- 单 kind canary、active 指针与 defensive copy；
- snapshot corruption、重开重新验签和 persistence CAS 失败；
- Storage adapter 重开恢复、双 session 竞争和 record/envelope metadata 损坏；
- Runtime/Storage Release HAR 的公共声明。

T47 主机验收另覆盖：

- shadow decision 无法改变 baseline，且观察数量有上限；
- 0/10000 basis points 与稳定 bucket 阈值；
- canary 未命中、异常或越界时回退 active/baseline；
- active 异常、越界与伪造 Registry view 时回退 baseline；
- 请求、artifact 和 decision 的复制隔离；
- durable active digest rollback 前后，同一 runner 的选择从新策略恢复到旧策略。

T46/T47 不构建产品 HAP，不使用 DevEco signingConfig，不安装或运行设备，也不证明 learned Router artifact 的质量收益。
