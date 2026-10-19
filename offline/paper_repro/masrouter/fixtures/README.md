# Research-only MasRouter handoff fixture

`research-only-handoff/` is a synthetic, deterministic handoff used only to exercise the T52 structural admission checker.

It is **not** a MasRouter checkpoint, training output, paper reproduction, parity result or deployable policy. The decision payload is a literal text fixture; the role/model/price snapshots use synthetic identities; the training and evaluation reports are placeholders. All claims are `notRun` and the cost is zero.

Validate it with:

```powershell
node offline/paper_repro/masrouter/check-masrouter-handoff.mjs --handoff offline/paper_repro/masrouter/fixtures/research-only-handoff
```

The checker verifies the contract identity, versioned feature envelope, Role Registry/Model Registry snapshots, ordered single/multi assignments, advisory-only candidate models, source digests, file safety, byte budgets and the absence of encoder/tokenizer/Python/PyTorch/optimizer/dataset/training-log content. Passing the checker only means the handoff is structurally admissible; it does not grant release, parity, shadow, canary or active status.

T52 review fix: the feature schema file must be a JSON object with exactly `schemaVersion`, matching both the contract and feature envelope. The 64 MiB package budget includes HANDOFF.json and SHA256SUMS and is checked before reading package contents. `totalListedBytes` remains the payload-file subtotal; `totalHandoffBytes` includes metadata. Git text conversion is disabled for this fixture tree so Windows checkouts preserve the committed hashes, including the literal binary-payload fixtures.
