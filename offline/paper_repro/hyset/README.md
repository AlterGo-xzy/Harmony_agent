# HYSET source freeze and reproduction admission

该目录是 harmony_agent 的 M14 离线论文复现域。T56/M14-A 只冻结公开来源、论文协议和未来适配边界，不把 HYSET 源码、Python Runtime、checkpoint 或 encoder 带入端侧 Runtime，也不提供新的任务控制入口。

本门完成的证据：

- 官方仓库固定到 commit `d0885766a9b60f778c35e161ad91e3a0d8af6dd7` 和 tree `e3b0bf2a3428640ece71ec5994571544100ec5a4`；源码归档 SHA-256 为 `745be2af629e11e641db1b6fd490942031c2167eed50f1424e293ab7724b2a80`。
- arXiv `2607.25718v2` PDF SHA-256 为 `f0b25a3a79294ea5503d43a7026f167a1346b3888d9a2a294c6718393c3852cd`；根源码许可证为 MIT。
- 固定 26 个关键源码、结果图和数据文件；内置 corpus 为 13,860 个工具，六个 test split 各 100 个 query。
- 固定源码声明的 Python 依赖、三组 seed、`M=5`、`K_neg=64`、`K1=15`、`K_pool=20`、`eta=0.3`、interaction regularization `0.01`、三种检索指标及论文结果表。
- `.gitmodules` 把 ToolBench/StableToolBench 声明为 submodule，但固定提交实际以普通 tree（`040000`）保存，并非 gitlink（`160000`）；本门分别固定两个 tree 和 Apache-2.0 license，不声称存在独立 submodule commit。
- 上游外部树出现 credential-shaped 路径 `external/stabletoolbench/openai_key.json`。本门没有读取其内容，它不是批准的凭据来源，后续也不得从中取值。

严格复现仍被十项来源缺口阻塞：上游没有给出 `best.pt` 的仓库/revision/digest；BERT encoder 身份缺失；Qwen encoder 只有名称，候选 `reasonwang/ToolGen-Qwen2.5-1.5B-Tool-Retriever` 未被上游权威绑定且没有 revision/digest；raw ToolBench instruction、UltraTool、reward cache、frozen-agent trajectories、judge 快照和冻结 Agent/DFSDT revision 均未锁定；external 声明与 Git 存储方式不一致。约 6.5 GB checkpoint 和约 3 GB encoder 的 README 描述不是可执行身份。

离线检查不访问网络，也不安装依赖：

```powershell
node offline/paper_repro/hyset/check-hyset-repro.mjs --check
node offline/paper_repro/hyset/test-hyset-preflight.mjs
```

`upstream-lock.json` 是来源锁；`reproduction-spec.json` 固定论文协议、未解决项、零执行声明和 harmony_agent 边界；`reports/preflight-v1.json` 由两者确定性生成。当前报告 SHA-256 为 `9a5fb008201cc129ebf8f2ff72d56fc7b57eb94b7cd149c15cc4b6624635f9f3`，11/11 fail-closed 自测通过。

适配只能作为 `DeterministicToolRouter` 内可选的 `LearnedRouterPort` scorer。输入必须先通过 hard eligibility，输出只能是 eligible subset；risk、permission、side effect 和 data boundary 仍由既有安全边界决定。新工具、未知 schema/relation、空 artifact、超时或异常均回退 deterministic top-k，`AgentRuntimeFacade` 仍是唯一任务控制入口。

checker 通过只证明公开来源和边界已经冻结，不证明依赖可安装、checkpoint 可取得、论文结果可复现、ArkTS parity、设备性能或生产发布。T57 可以在没有真实 checkpoint 的前提下建立 research-only handoff 合同和规模基线；T58 的下载、安装、模型运行与 parity 继续等待单独授权和身份补齐。
