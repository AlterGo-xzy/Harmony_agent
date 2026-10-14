# @harmony_agent/agent-runtime

`@harmony_agent/agent-runtime` 0.13.0 是不依赖 UI 的 Agent Runtime HAR。目前提供 Promise-based `AgentRuntimeFacade` 公共接口、异步 `SemanticPlannerPort`、M03 内部 Session/Planner/Runtime 编排、M04 Registry 与确定性 Router、M09-B 生产组合 factory、外部授权决定到内部短期授权凭证的转换、凭证绑定校验、预算预留以及 secret 脱敏。

外部宿主只能提交 `AuthorizationDecision`；`AuthorizationGrant` 由本模块内部签发并绑定 task、step、operation、tool identity、schema、arguments、policy version 和预算预留。

`Index.ets` 只把 `AgentRuntimeFacade` 暴露为业务控制接口。`createProductionAgentRuntime` 接收版本化 composition config、Planner/Router/Tool preparation ports、一个启用 Adapter 的 factory 和持久化端口，返回的仍是 `AgentRuntimeFacade`。0.13.0/composition 2.4 的异步 `createRecoveredProductionAgentRuntime` 通过只读 `ProductionRuntimeRecoverySourcePort` 枚举任务、读取 authority，并在 Facade 暴露前完成 checkpoint 重建、budget/policy authority hydration 和恢复事件持久化；遇到 active operation 时，先通过 persistence port 的专用 normalization 门把恢复 checkpoint 与 durable operation/fencing 原子对齐。恢复 source、factory、ports 和 DTO 都不能创建任务、推进状态或签发执行 grant；M03 的 `RuntimeCoordinator` 和生产实现类均保持模块内部可见。

生产组合层按 snapshot version 暂存检查点并等待异步持久化完成。0.13.0/production composition 2.4 延续每个 checkpoint 的同状态 `RuntimeDurableAuthorityPayload`，并把 task/snapshot version、policy version、完整 task/step/provider budget scopes、全部 reservation 以及当前可证明的 policy/operation 绑定交给 persistence port。等待授权 checkpoint 携带 version 1 request；dispatch 准备 checkpoint 携带 version 3 decision/grant 和 `PREPARED` operation，`beforeDispatch(checkpoint, expectedPreviousVersion, context, authority)` 成为宿主单 CAS 原子提交边界，成功后才调用 Adapter。active recovery 使用 `normalizeRecoveredOperation` 专用门，普通 `saveCheckpoint` 仍不能创建或回退 operation；outcome/reconciliation 之后的 operation、fencing 和结算状态仍由对应 persistence 方法维护。持久化端收到独立深拷贝，不能改写 Runtime 保留的 checkpoint 或 authority。

同一 Facade 实例的公共操作和异步 Adapter completion 继续进入同一个调用顺序 FIFO；前一项 durable lifecycle 未结束时，后一项不会进入协调器或提前完成，单项拒绝不会毒化队列。同步 Adapter completion 仍在当前 dispatch 生命周期内登记后应用，避免重入自等待。`RuntimeTaskRecoveryCheckpoint` 1.1 将原始 submission、公开 snapshot 与 envelope、workflow、scheduler、事件、规划状态、等待项、在途 invocation 和稳定关联 ID 放在同一个版本化保存单元；原始 submission 用于重建 requestId 的精确去重。`RuntimeCheckpointValidator` 在写入前以及持久化回读后校验版本、submission normalization、事件顺序、workflow/scheduler 和 task/request/session/dispatch 绑定；1.0 或绑定不一致的检查点 fail-closed。该检查点和 authority payload 都是敏感恢复数据，宿主必须按 privacy class 施加访问控制和加密，不能把它们作为公共事件输出。

内部 `RuntimeCoordinator.restoreCheckpoint` 可以在新协调器中重建 Session、事件、workflow 和 scheduler。在途无副作用步骤转为待重试，带副作用步骤转为等待对账，旧 dispatch ID 被撤销。除 COMPLETED/CANCELLED 外，所有恢复记录保持 `RECOVERY_AUTHORITY_REQUIRED` 锁定；Policy/Budget durable authority 完成 hydration 前，不能授权、推进、重规划、控制、对账或接受旧 Adapter completion。该内部方法不从公共 `Index.ets` 导出，不构成第二任务入口。

0.8.0 新增 storage-neutral `RuntimeRecoveryAuthority` 1.0 与只读 `RuntimeRecoveryAuthorityValidator`。权威图必须绑定原检查点 snapshot version、正数 durable revision 和当前 policy version，并携带完整 task/step/provider budget scopes 与全部 reservation；等待授权状态还必须匹配 version 1 policy request，在途 Tool 则必须匹配 version 3 decision/grant、operation intent、幂等模式、副作用分类、fencing/dispatch 状态和同一预算预留。校验或预算 hydration 任一失败都不解除锁；成功后内部协调器才允许原有控制路径继续。DTO 与 validator 只处理数据，不能创建或推进任务。

Tool dispatch 携带 `DispatchPersistenceContext` 1.0：只包含 operation/dispatch/invocation/attempt、Tool identity、参数摘要、幂等模式、预算预留和 Provider 等稳定元数据，不包含任务正文、工具参数 JSON、凭据或授权凭证。`beforeDispatch` 获得独立上下文副本，Adapter 获得完整请求的独立深拷贝；两者都不能改写 Runtime 保留的 pending 绑定。非 Tool step 没有 operation context。Adapter 只获得 completion-only sink；回调必须匹配 Runtime 已发出的 task、step、dispatch 和 Tool invocation，重复或伪造回调不会推进任务。同步回调会在 dispatch 返回且内部状态登记完成后再应用。

`createFakeAgentRuntime` 和 `FakeAgentConsumer` 是 M09-A 的显式测试实现；它们用于无 UI 合同验收，不伪装成生产 Planner、Provider、Store 或系统 Tool。M02 的 `PolicyGateway` 仍保持模块内部可见。

M03 当前提供：

- `TaskSubmission -> TaskEnvelope` 规范化、ID 分配与重复提交去重；
- `TaskAnalyzer -> CollaborationSelectorPort -> SemanticPlannerPort` 两阶段规划；Planner 的 plan/resume/replan 均为 Promise，Facade 串行队列会等待规划完成后才允许 Tool dispatch；Promise 拒绝时任务以稳定的 `plannerInvocationFailed` 证据闭合，底层异常文本不会进入公共快照或事件；
- Planner 结果必须通过 M01 `WorkflowGraphValidator`，文本不能直接触发 adapter；
- Scheduler 驱动、暂停/恢复、取消、澄清、授权等待、异步 dispatch、迟到完成拒绝和未知结果对账；
- 受保护的成功、运行中和 `UNKNOWN_OUTCOME` 步骤不能被 partial replan 替换；
- planner call、agent activation 和 replan 使用量显式计数。

M04 当前提供：

- Model、Role、Tool、Workflow 四类内存 Registry；稳定 ID、版本、调用方提供的 digest 与确定性快照身份分离；同版本内容漂移拒绝；
- Model/Tool Router 先执行 region、隐私、能力、风险、副作用、权限、数据边界、网络和成本硬过滤，再进行确定性评分；
- learned Model/Tool policy 可关闭；越界选择、低置信度、异常或不可用时回退到确定性 baseline；
- Context Router 按系统、用户、已验证依赖、短期历史、允许的长期记忆与可选内容顺序守 token 预算；
- Collaboration Router 对 Runtime composition port 保持单 Agent，只有显式 route 请求、可并行任务、独立能力和至少两个 activation 预算时才返回 multi；
- Tool Router 不依赖 embedding，并保持 schema、description、retrieval relation 的版本职责分离。

当前限制：Registry 仍是内存实现，快照 `snapshotDigest` 是由调用方提供的 entry digest 组成的确定性身份串，不声称由 Runtime 重新计算密码学哈希。0.13.0 已冻结异步 Facade、异步 Planner 生命周期、同实例 FIFO、checkpoint/authority 写入，以及无在途和 active operation 的启动恢复；M05-A bridge 可把 active operation 保守转入 `WAITING_RECONCILIATION`，不会在重启后重放 Adapter，具体 RDB composition 和 API 26 跨进程恢复已由 T26 验收。真实语义 Planner、生产 credential store、真实 learned Router artifact 或带写副作用 Tool 仍未接入。映射和时序边界见 `docs/AGENT_RUNTIME_STORAGE_INTEGRATION.md`。
