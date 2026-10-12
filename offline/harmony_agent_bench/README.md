# harmony_agent Bench Pilot

该目录保存 S6 的离线、版本化 benchmark 输入与报告。它不进入端侧 Runtime，也不提供第二个任务控制入口。

当前 `fixture-baseline-v1` 用于证明以下内容可重复：

- 十二种任务类型各有一个固定 case；
- Strong Single Agent 与 Multi Agent 使用相同 permission/context policy；
- model、provider、region、价格、contract schema、router policy、数据集和日期均固定；
- 质量、token、成本、延迟字段、工具、Agent、恢复和 Router 指标均进入报告；
- 32、128、512 项 Tool Registry fixture 均能选择唯一目标工具。

运行：

```powershell
node offline/harmony_agent_bench/run-fixture-baseline.mjs --check
```

使用 `--write` 重新生成报告。生成器只使用 Node 内置模块，不安装依赖。

## 证据边界

当前 provider/model 是确定性本地 fixture，价格为零，延迟采用明确标记的虚拟零时钟。该报告只能作为数据完整性、指标管线和重复性 baseline，不能比较真实模型质量、真实成本、真实性能或设备行为。完成 S6 仍需使用生产候选 Provider/系统链路生成独立报告，并冻结真实价格、region、模型版本和运行日期。
