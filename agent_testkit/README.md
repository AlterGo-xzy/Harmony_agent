# @harmony_agent/agent-testkit

`@harmony_agent/agent-testkit` 是 M10 的纯 ArkTS 测试支持 HAR。它让各模块在没有产品页面或产品 Entry HAP 的情况下使用同一套确定性故障、集成场景和 benchmark 统计契约。

## 当前交付

- `DeterministicFaultInjector`：按 target、phase 和 occurrence 精确返回故障决策，覆盖网络断开、timeout、429/5xx、认证失败、权限拒绝、schema drift、重复响应、应用重启、预算耗尽、低质量输出和不可逆调用未知结果。
- `IntegrationFixtureCatalog`：固化架构文档中的 10 个共用集成场景及最低不变量。
- `BenchmarkManifestValidator`：要求固定 model、provider、region、价格快照、contract schema、dataset、router policy 和日期。
- `BenchmarkEvaluator`：拒绝未知 arm、非法计量和重复样本，并导出质量、token、成本、p50/p95、工具、Agent、恢复和 Router 指标。
- Strong Single Agent 与 Multi Agent 比较必须使用相同 permission policy 和 context policy。

## 集成边界

TestKit 不提交、控制或恢复任务，不签发授权，也不调用 Tool、Provider、Storage 或系统 Kit。宿主仍必须只通过 `AgentRuntimeFacade` 控制任务。Adapter 测试代码读取 `FaultDecision` 后，在自身边界注入对应故障；TestKit 不把 fake 行为伪装成生产能力。

本模块是 M10 TestKit 基础，不代表 harmony_agent Bench Pilot 已完成真实 model/provider 对比，也不提供产品 UI、产品 HAP、设备能力或签名验收。

## 验证

```powershell
$env:DEVECO_SDK_HOME='D:\DevEco\DevEco Studio\sdk'
& 'D:\DevEco\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=agent_testkit@default -p product=default test --no-daemon
& 'D:\DevEco\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=agent_testkit@default -p product=default -p buildMode=release assembleHar --no-daemon
```
