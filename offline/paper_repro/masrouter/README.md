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
