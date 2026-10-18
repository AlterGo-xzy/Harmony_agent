# T51 / M13-B review

## Result

The MasRouter environment, dataset, provider/model-revision and price input contract is complete as an offline, fail-closed inventory. The deterministic checker report digest is `sha256:91a6ef1d965430cf12d44329a61697048692dca94f38268ca0f25875d5cd8dc8`; the high-value self-test suite passes 9/9.

## Delivered

- Four JSON Schema documents: environment lock, dataset lock, provider/model revision lock, price snapshot.
- `environment-candidates.json`: 34 direct dependency candidates (27 benchmark-entrypoint transitive, 7 tool-only) plus pyarrow/fsspec/huggingface-hub as implicit runtime dependencies; all versions unresolved.
- `dataset-lock.json`: GSM8K, HumanEval, MATH, MBPP and MMLU with required paths, split semantics, blocking issues and `executionReady=false`; no dataset digest is claimed.
- `model-pools.json`: paper 4-model core pool, DeepSeek-V3 inductive validation and source 5-model profile kept separate; all revisions/regions unresolved.
- `price-snapshot-candidate.json`: Claude 3.5 Haiku 1.0/5.0 vs 0.8/4.0 conflict explicit; all entries remain source metadata only and `costClaimsAllowed=false`.
- `unresolved-issues.json`: 17 open issues, 13 blocking.
- `input-contract.json`: T51 claims, readiness flags and zero-execution metadata.
- `check-masrouter-inputs.mjs` and `test-masrouter-inputs.mjs` with deterministic report generation.

## Architecture boundary

- The work is entirely under `offline/paper_repro/masrouter/` plus status/architecture documentation.
- No online Runtime, HAR, HAP, Registry, Router, Policy Gateway or `AgentRuntimeFacade` code was modified.
- No second task-control entry was created.
- The research source, Python runtime, sentence encoder and checkpoints are not vendored or packaged.

## Evidence boundary

Completed: source archive SHA-256 verification; read-only inspection of 50 Python files, README, template.env and five benchmark entrypoints; import reachability analysis; four schemas; six input documents; deterministic checker report; 9/9 fail-closed tests; JSON parse 11/11; `git diff --check` passed with line-ending warnings only.

Not run: dependency installation, dataset download, dataset digest computation, model download, credential reads, Provider calls, training, benchmark execution, ArkTS/Hypium tests, HAR/HAP build, signing, installation, device execution, parity, shadow, canary or active release.

Strict reproduction remains blocked on a resolved dependency lock, frozen dataset digests, provider/model revisions and an officially reconciled price snapshot. T54 remains paused. This is a recorded environment gap, not a runtime defect.
