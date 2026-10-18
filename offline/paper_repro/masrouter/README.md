# MasRouter source freeze and reproduction admission

该目录是 harmony_agent 的 M13 离线论文复现域，不进入端侧 Runtime，不打包 Python、sentence-transformers 或模型权重，也不提供任务控制入口。

T50/M13-A 只完成上游来源和复现协议冻结：

- 官方仓库固定到 commit `e005f7696fe0c0412563f6cd67f4cd3712fa2822` 和 tree `e4d618f81675a46ed6e2f5e6ee1970519f1afa5b`；
- 固定 Apache-2.0 许可证、源码归档、15 个关键文件和 arXiv `2502.11133v1` 的 SHA-256；
- 分开记录论文协议与当前源码协议，避免把 DeepSeek 归纳验证、协作模式和价格元数据的差异混为一套配置；
- 明确记录上游没有依赖清单、没有 checkpoint，README 的入口大小写与仓库目录不一致，且 Claude 价格元数据存在冲突；
- 预注册 harmony_agent 适配只能替换 `CollaborationPlanSelectorPort` 策略，角色只能来自 Role Registry，Multi 必须先保留完整激活预算，低置信度、超时和不兼容 checkpoint 回退 Single；
- 明确记录没有安装依赖、读取凭据、运行训练、调用 Provider 或执行 benchmark，费用为零。

离线检查不访问网络，也不安装依赖：

```powershell
node offline/paper_repro/masrouter/check-masrouter-repro.mjs --check
node offline/paper_repro/masrouter/test-masrouter-preflight.mjs
```

`upstream-lock.json` 是来源锁，`reproduction-spec.json` 是复现和架构适配预注册，`reports/preflight-v1.json` 由两者确定性生成。checker 通过只证明本次源码审计和边界冻结完整，不证明上游环境可安装、论文结果可复现或策略已接入运行时。

下一门需要先在隔离研究环境中补齐并冻结依赖、数据集摘要、Provider 模型 revision 和价格快照，再决定是否申请安装与付费实验授权。MTRouter 本地训练仍保持暂停，MasRouter 不绕过该决定，也不会把研究模型随 HAR/HAP 打包。

## T51/M13-B 环境、数据与价格输入合同

T51 在固定 commit `e005f7696fe0c0412563f6cd67f4cd3712fa2822` 上只读检查了 50 个 Python 文件、README、`template.env` 和五个实验入口，把 T50 已发现的环境缺口转成可审计的输入合同。源码归档按 T50 记录的 SHA-256 校验后仅在独立临时目录解压，未保留、未执行、未安装依赖。

交付物：

- `schemas/environment-lock.schema.json`：Python/PyTorch/CUDA 或 CPU 以及依赖版本的 lock schema；
- `schemas/dataset-lock.schema.json`：数据集来源、split、大小、SHA-256 和记录数 schema；
- `schemas/provider-model-lock.schema.json`：论文模型池、源码模型池和 Provider revision schema；
- `schemas/price-snapshot.schema.json`：价格快照与冲突解决 schema；
- `environment-candidates.json`：34 个直接依赖候选（27 个入口可达、7 个工具专用）和 3 个隐式运行时依赖，全部标记 `unresolved`；
- `dataset-lock.json`：GSM8K、HumanEval、MATH、MBPP、MMLU 五个数据集，全部缺少 digest 且 `executionReady=false`；
- `model-pools.json`：论文 4 模型核心池、DeepSeek-V3 归纳验证和源码 5 模型 profile 严格分离；
- `price-snapshot-candidate.json`：Claude 3.5 Haiku 的 1.0/5.0 与 0.8/4.0 冲突保持显式，`costClaimsAllowed=false`；
- `unresolved-issues.json`：17 项未解决问题（13 项 blocking），包括缺失依赖清单/checkpoint、MMLU download 模块缺失、路径大小写、未播种 20/80 split、MBPP 未固定远端 revision、MATH 519 子集不可重建、MMLU 测试切片隐式依赖 dev 大小、环境变量漂移、DeepSeek 客户端大小写选择、tokenizer 编码固定为 gpt-4o 等；
- `input-contract.json`：T51 claim/readiness/zero-execution 元数据；
- `check-masrouter-inputs.mjs` 与 `test-masrouter-inputs.mjs`：确定性 checker 和 9 项 fail-closed 自测；
- `reports/input-contract-v1.json`：确定性报告。

离线检查不访问网络、不安装依赖：

```powershell
node offline/paper_repro/masrouter/check-masrouter-inputs.mjs --check
node offline/paper_repro/masrouter/test-masrouter-inputs.mjs
```

T51 只完成“环境输入合同”，不表示依赖可安装、数据集已下载、Provider 可调用、论文可复现或策略已接入运行时。所有依赖版本、数据集 digest、模型 revision/region 和官方价格仍需在 T54 前的独立授权批次中冻结；T54 继续暂停。
