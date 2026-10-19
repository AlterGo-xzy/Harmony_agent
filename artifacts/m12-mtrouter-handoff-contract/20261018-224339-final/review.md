# M12 training handoff contract review

- Result: the offline handoff admission contract and checker passed 15/15 fail-closed tests.
- The checker binds the frozen T48 upstream identity, preserves model order, validates parameter count by model-pool size, hashes every listed regular file, and rejects extra files and unsafe paths.
- Decision payload is limited to 5 MiB; encoder/tokenizer/Python runtime/optimizer state are forbidden; the total handoff is limited to 64 MiB.
- Runtime integration remains the existing LearnedRouterPort with learned routing disabled by default and deterministic fallback. Network work inside synchronous route() is rejected.
- The original T48 preflight still passes 5/5 and its report digest is unchanged.
- No real handoff, dependency installation, model download, training, checkpoint, ArkTS/device parity, shadow, canary, active release, signing, HAP build, installation, or device execution occurred.
