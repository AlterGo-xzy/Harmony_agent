# MTRouter strict reproduction boundary

该目录是 harmony_agent 架构中的 M12 离线论文复现域，不进入端侧 Runtime，也不提供任务控制入口。

T48 只完成上游与实验协议冻结：

- 官方仓库固定到 commit `ee9e4573a128c3e54aa8c83800318bfb783c4dfe` 和 tree `6911bcf33bfdd30d6f414c09b5f5d14c5deeb913`；
- 固定 MIT 许可证、源码归档、`pyproject.toml`、README 和 arXiv `2604.23530v1` 的 SHA-256；
- 按论文固定三次运行、六模型池、ScienceWorld/HLE 数据划分、训练参数、每 episode US$2 预算和 50/30 turn 上限；
- 预注册性能均值必须落入论文报告的一个标准差，成本相对偏差不超过 5%；模型、数据划分或价格快照漂移时结果标记为不可比较；
- 明确记录依赖尚未安装、凭据未读取、Provider 请求与 benchmark 均未执行、费用为零。

离线检查不访问网络，也不安装依赖：

```powershell
node offline/paper_repro/mtrouter/check-mtrouter-repro.mjs --check
```

`upstream-lock.json` 是来源锁；`reproduction-spec.json` 是复现预注册；`reports/preflight-v1.json` 是由两者确定性生成的 T48 报告。下一门只有在单独授权安装隔离依赖后，才能建立原环境并运行上游测试。真实模型调用、Serper 查询和任何付费 benchmark 还需要独立的配置核对、费用封顶与批次授权。

MTRouter 的 learned decision 最终只能替换 M04 `ModelRouter` 的软评分；Runtime 的 hard eligibility、预算、Policy Gateway、Artifact Registry/release runner 与 `AgentRuntimeFacade` 边界不变。论文复现结果和 harmony_agent adaptation 结果必须分别报告。

## 独立训练仓库 handoff admission

独立训练仓库只交付研究候选，不直接进入 Runtime。主仓库使用以下纯 Node checker 验证 handoff 目录：

```powershell
node offline/paper_repro/mtrouter/check-mtrouter-handoff.mjs --handoff <handoff-directory>
```

`handoff-contract.json` 固定上游身份、history encoder 的外部服务部署方式、现有 `LearnedRouterPort` 接口边界、5 MiB decision payload 上限和 64 MiB handoff 上限。checker 会逐文件验证 `HANDOFF.json`、`SHA256SUMS`、大小和摘要，拒绝路径穿越、符号链接、未列出的额外文件、encoder/tokenizer/Python runtime/optimizer state、同步 Router 网络调用，以及训练仓库对 ArkTS/device/shadow/canary/active 的越权声明。

运行 fail-closed 自测：

```powershell
node offline/paper_repro/mtrouter/test-mtrouter-handoff.mjs
```

checker 成功只表示 handoff 结构、来源和包体边界通过离线准入，输出固定为 `researchCandidateOnly`。它不证明论文复现、训练质量、Python/ArkTS parity、设备性能或发布资格。
