# 验收矩阵

最后更新：2026-10-11。M07 Provider Connector 为主机 fake-transport contract gate；M08 首个只读 Native Tool 已完成主机、构建与签名 API 26 设备运行门；M09-B 生产 Facade 已完成 T25 本地 composition/test/HAR 门，并补齐 M05-A active operation 的 durable 单 CAS 恢复归一化。

| 验收项 | 主机侧证据 | 设备侧状态 |
|---|---|---|
| JSON-RPC 编解码、乱序响应、结构化错误 | ArkTS 单元测试已运行通过 | 不需要设备 |
| SSE 分块、多事件、注释、畸形数据 | ArkTS 单元测试与 Node Fixture 契约已运行通过 | 不需要设备 |
| 超时、取消、响应大小限制 | ArkTS 分类/取消/字节上限测试已运行通过 | 真实 HTTP 场景已编译进 ohosTest HAP，未运行 |
| 分页、重复游标、空目录缓存与显式刷新 | ArkTS 单元测试已运行通过 | 不需要设备 |
| 文本、图片、音频、资源链接、嵌入资源、结构化内容和未知块 | ArkTS 单元测试已运行通过 | 现代 Fixture 调用已准备，未运行 |
| 现代 `2026-07-28`、旧式 `2025-11-25`、auto 协商 | ArkTS 单元测试与 Node Fixture 契约已运行通过 | 现代真实网络测试已编译，未运行 |
| 401、403、5xx、网络和超时不误回退 | ArkTS 单元测试与 Node Fixture 契约已运行通过 | 对应 ohosTest 用例已编译，未运行 |
| 安全查询只在无 HTTP 响应时重试一次；工具调用不重试 | ArkTS 单元测试已运行通过 | 不需要设备 |
| 两个 Server 并发、同名工具引用与单 Server 故障隔离 | ArkTS 管理器测试与 Node Fixture 契约已运行通过 | 不需要设备 |
| 未注册策略或策略异常时拒绝，且不发送 `tools/call` | ArkTS 传输请求计数断言已运行通过 | Fixture 统计验证已编译，未运行 |
| 认证异常分类以及认证值不进入报告/统计 | ArkTS 与 Node Fixture 契约已运行通过 | 不需要设备 |
| Release HAR 不含 Node/stdio 运行时依赖 | Release 构建与 HAR 审计已运行通过 | 不需要设备 |
| 真实设备网络、断开连接、重连与资源释放 | 不可由主机运行替代 | 已编译进 ohosTest HAP，等待设备 |
| 应用后台/前台恢复 | 无主机等价验证 | AbilityDelegator 生命周期往返与恢复后查询已编译进 ohosTest HAP，未运行 |

主机侧最终结果：ArkTS `26/26`，Node Fixture `10/10`，验收阶段 `PASSED=7 FAILED=0 SKIPPED=1 EXIT=0`。

设备阶段被跳过的唯一原因是 HDC 未检测到设备或模拟器。HAP 构建成功不等于安装、签名或运行成功；连接设备后应使用：

```powershell
.\tools\test-mcp.ps1 -Device Required -Protocol Both -AdvertiseHost <设备可访问的本机地址>
```

脚本不会修改防火墙。运行前需要由操作者自行确认设备能访问该地址和临时端口，并提供可安装 HAP 所需的现有签名配置。

## Agent Runtime 主机侧验收

| 模块 | 结果 | 已证明 | 未证明 |
|---|---:|---|---|
| `agent_contracts` | 14/14 | DTO、codec、shape validation | 跨版本生产兼容性 |
| `agent_core` | 21/21 | DAG、Scheduler、Recovery、Budget；完整预算总账原子 hydration | 真实 Planner/Provider/Tool 与设备运行 |
| `agent_runtime` | 60/60 | Policy、Headless Fake、M03 编排、M04 Registry/Router、M09-B Production Facade；Promise durable gate、同实例 FIFO、启动恢复、authority hydration、event replay、active operation 对账转换与 fail-closed | 真实 Planner/Provider/Tool、签名设备进程退出/重启运行 |
| `agent_storage` | 47/47 | M05-A/M05-B durable recovery；checkpoint/authority、operation/budget、lease/fencing 与恢复 checkpoint 单 CAS 发布；0.8.0 RDB composition 已通过类型检查与 unsigned HAP 构建 | T07/M05-A 7/7 与 T08/M05-B 3/3 是既有 schema 的签名设备证据；T26 两阶段跨进程 fixture 尚未运行，宿主加密仍未证明 |
| `agent_connectors` | 28/28 | M06 MCP adapter 13；M07 Provider connector 15，覆盖 model/embedding/remote API 快照、stream、usage/cost、credential、取消/timeout、grant 与未知写结果 | 未运行真实 Provider/设备网络；不属于本地 connector 门 |
| `native_tools` | 12/12 | API 26 battery descriptor、capability probe、M02 grant 复核、参数/identity fail-closed、后台限制、取消、异常、结果归一化和 M03 dispatch 接线 | 签名 `BatteryStatusDevice` 1/1，完成安装、真实系统读取、卸载与 bundle 不存在核对；需要权限的 Kit 尚未选定 |

M03 用例覆盖提交去重与冻结时间语义、validated workflow dispatch、澄清与授权分离、内部 grant 后才允许工具 dispatch、暂停/恢复、未知副作用对账、取消后延迟对账、迟到 completion 拒绝、单调 sequence/version，以及 partial replan 保护成功和未知结果。该结果来自 `agent_runtime@default test` 的主机侧 Hypium 运行；HAR 构建不等于 HAP、安装或设备验收。

M04 用例覆盖 Registry 顺序/复制隔离/同版本冲突、模型与工具 hard eligibility 先于 learned policy、learned 关闭和低置信度回退、确定性 tie-break、无 embedding 工具路由、累计工具成本、description/retrieval version 分离、Context token 预算、未验证依赖排除、single-first 与独立能力 multi 门。该结果同样只来自主机侧 Hypium；未加载真实 checkpoint 或 embedding。

M09-B 新增 8 项用例覆盖：状态 snapshot 的顺序持久化、dispatch 前持久化准备、持久化拒绝时不调用 Adapter、Policy Gateway 后才进行 Tool dispatch、同步 Adapter completion 延迟到 dispatch 登记完成、task/step/dispatch/invocation 回调绑定、控制命令重放、澄清、未知结果对账、事件回放、订阅释放与 shutdown。结果来自主机侧 Hypium 和 Release HAR 构建；fixture persistence/adapter 不等于异步 durable RDB、真实 Provider/Tool、跨进程恢复、签名 HAP、安装或设备运行。

0.5.1 在同一 52 项套件中增加断言：非 NONE 幂等模式缺少 key 时 dispatch 前拒绝；Tool 写前上下文包含 dispatch/operation/budget/provider 绑定；`beforeDispatch` 只取得不含任务正文、参数 JSON 或授权凭证的上下文副本；持久化实现与 Adapter 修改各自副本都不会污染 Runtime 保留的请求。同步 `ProductionRuntimePersistencePort` 与 Promise/CAS `DurableExecutionRecoveryStore` 的宿主 bridge 仍未实现，映射与时序见 `docs/AGENT_RUNTIME_STORAGE_INTEGRATION.md`。

0.6.0 在同一套件中继续验证 `RuntimeTaskRecoveryCheckpoint` 1.0：等待授权状态保留 workflow/scheduler/policy request/event sequence；pending dispatch/operation 与 active invocation 在任何 Adapter 调用前先保存；完成后清除在途字段；返回对象与生产 persistence fixture 均按副本隔离。`saveCheckpoint`/`loadCheckpoint` 已替换摘要级保存端口，但检查点校验、Policy/Budget durable hydration、协调器重建和跨进程运行尚未实现。

0.6.1 在同一 52 项套件中加入 `RuntimeCheckpointValidator` 断言：Runtime 生成的等待授权与在途 checkpoint 必须通过版本、公共契约、身份绑定、事件序列、workflow/scheduler 和 pending state 校验；伪造 snapshot taskId 的对象必须失败。生产 Facade 在保存前和 `loadCheckpoint` 回读后执行校验，并对请求 taskId 重新绑定；无效持久化数据以 `PERSISTENCE_FAILURE` fail-closed。该结果仍是主机 gate，不等于协调器重建、异步 durable bridge 或跨进程恢复。

0.7.0 的 53 项套件继续验证 checkpoint 1.1 和协调器重建：原始 submission 保证重启后的 requestId 精确去重；1.0 格式拒绝；等待授权状态在新协调器中恢复但保持 authority lock；在途无副作用步骤不调用 Adapter 并回到待重试状态；在途副作用步骤进入等待对账；旧 completion、授权、推进、控制和 FAILED replan 在 durable Policy/Budget hydration 前统一返回 `RECOVERY_AUTHORITY_REQUIRED`；重复 Policy request 冲突在提交 Session/预算状态前拒绝，随后使用干净检查点仍可恢复。该门没有把恢复接入生产 Facade 或 Promise/CAS RDB，仍不等于跨进程验收。

0.8.0 的 54 项 runtime 套件新增 authority hydration 场景：错 checkpoint snapshot version 与错 operation-policy 绑定都拒绝并保持锁；完整 budget scopes/reservations、等待中的 version 1 policy request 或在途 version 3 decision/grant/operation 全部匹配后才解锁；恢复的带副作用任务只接受对账，期间 Adapter 调用数保持 0。T19 由 storage 39 项中的 M05-A 26 项验证 schema 1.2 opaque checkpoint、任务枚举和 checkpoint/authority 单 CAS。T20 将 runtime 增至 55 项：Facade、persistence port 与 completion sink 均 Promise 化，dispatch 的最终 checkpoint 与 authority 共用异步 `beforeDispatch` 提交门；人为挂起该 Promise 时 Adapter 保持 0 调用，释放后才 dispatch。T21 将 runtime 增至 57 项：第二个重叠提交在前一个 durable gate 完成前保持未完成且 Adapter 为 0 调用；前一个命令契约拒绝后，后续有效提交仍能执行。

T22–T24 将 runtime 增至 59 项、storage 增至 45 项，完成生产 persistence bridge、durable authority 回读、任务枚举、启动恢复、event/policy replay，以及无在途 operation 的 backend reopen → recovered Facade → 继续授权链路。T25 将 runtime 增至 60/60、storage 增至 47/47：活动调用在启动时转入 `WAITING_RECONCILIATION`，bridge 在一次 backend CAS 中接管 fencing、把 operation/budget 归一化为 `UNKNOWN_OUTCOME`、释放恢复 lease 并保存下一版本 checkpoint；CAS 冲突和绑定不一致均 fail-closed，Adapter 调用保持为 0。T26 新增 `createRdbRecoveredAgentRuntime` 与 `RuntimeRdbDeviceRecovery` 的 seed/recover 两阶段 fixture；Storage 47/47、Release HAR 和完整依赖图 unsigned HAP 均通过，但签名、安装、真实进程 force-stop、recover 运行和卸载核对尚未执行。

M05-A 主机用例覆盖 task CAS/copy、opaque Runtime checkpoint 与任务枚举、checkpoint/authority 单 CAS 发布、operation/reservation/完整 budget scope 图原子 prepare、version 3 Policy/Grant 绑定、全部 reservation 与 scope 防御性读取、稳定 ID 冲突、lease/fencing、三类崩溃语义、UNKNOWN 对账、实际预算/receipt 和 scope 聚合结算、trace retention、schema/migration/corruption，以及 durable CAS 失败不发布、两个 session 单胜者和 reopen 前未知状态固化。

M05-B 当前 13 项主机用例覆盖：类型化记录的 digest 与显式版本、复制隔离、确定性分块/词法索引与 owner 隔离、敏感记忆和原始个人轨迹默认不检索、批量导入原子拒绝、导出默认仅 `SHAREABLE` 且标题/正文/标签脱敏、更新与删除级联失效、stale artifact 拒绝，以及 durable CAS 失败不发布、并发 session 单胜者、重开恢复并重建索引、损坏 fail-closed 和显式 schema migration。`RdbMemorySnapshotBackend` 已通过 API 26 类型检查；当前命名签名包的设备验收已证明 close/reopen、索引重建、真实 RDB 损坏注入和 stale session CAS 竞争，宿主加密配置仍未证明。

M05-B 的 `MemoryDeviceRecovery` 当前命名签名主 HAP 与 ohosTest HAP 已在 API 26 实际运行 3/3，通过签名验证、安装、RDB close/reopen/索引重建、stale session CAS 单胜者、损坏 fail-closed 和最终卸载检查。证据位于 `artifacts/t08-signed-device-acceptance/20261002-195000/`。

M08 首个工具是 permission-free 的只读 battery status：主机 contract test 12/12；Release HAR 和 API 26 主/ohosTest HAP 构建通过。签名包已在 API 26 模拟器完成验证与安装，真实 `SystemNativeCapabilityProbe` 与 `SystemBatteryStatusPort` 的 `BatteryStatusDevice` 运行 1/1 通过，随后卸载并确认 bundle 不存在。该证据关闭首个 battery slice 的设备门，但不满足未来 permission-required Native Kit 的拒绝/允许完成标准，也不证明写能力。

设备侧 `StorageDeviceRecovery` 的 7 项测试覆盖：HAR 加载；PREPARED/budget close-reopen；调用中退出；已收到结果但提交前退出；已提交 receipt/实际预算；两个 stale session 竞争 lease/CAS；摘要损坏 fail-closed。2026-10-01 在 API 26 模拟器 `127.0.0.1:5555` 上实际报告 `Tests run: 7, Failure: 0, Error: 0, Pass: 7`。签名主 HAP 与 ohosTest HAP 均安装成功，测试 bundle 随后卸载并验证不存在；证据目录为 `artifacts/t07-device-acceptance/20261001-211416/`。因此 T07/M05-A 已通过本地实现与设备验收门，但尚不等于生产 Facade、具体写 adapter 或发布交接已经完成。
