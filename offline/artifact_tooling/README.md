# harmony_agent Artifact contract

This directory owns the offline packaging and verification boundary for M11. It does not expose task-control APIs and does not replace `AgentRuntimeFacade`.

## T44 contract

`ArtifactManifest` is exported by `@harmony_agent/agent-contracts`. A released manifest records:

- one of `checkpoint`, `policy`, or `workflow` as `artifactKind`;
- a full Git commit ID, source license, and ordered data-lineage identifiers;
- a frozen model/provider snapshot and an ordered runtime-compatibility declaration;
- a generic SHA-256 payload digest in `artifactDigest`;
- separate JSON objects for paper reproduction, port parity, and harmony_agent adaptation results;
- approval, signing, lifecycle, and rollback metadata.

`checkpointDigest` remains as a wire-compatibility alias. New packages use `artifactDigest`; if both fields are present they must match.

## Validation boundary

`ContractValidator.validateArtifactManifest` performs deterministic shape and release-admission checks. It rejects truncated commit IDs and digests, invalid JSON objects, duplicate lineage or compatibility entries, incomplete released evidence, partial signature metadata, unsigned canary/active manifests, and rollback records without a different target digest.

An unsigned but complete `shadow` manifest is allowed because shadow evaluation cannot select runtime behavior. `canary`, `active`, and `rolledBack` manifests require an approved release record and complete detached-signature metadata.

`ContractValidator.validateArtifactLifecycleTransition` allows idempotent writes and these controlled transitions:

```text
disabled -> shadow
shadow -> canary | disabled
canary -> active | shadow | rolledBack
active -> rolledBack
rolledBack -> disabled
```

Skipping directly from `disabled` or `shadow` to `active` is rejected.

## Signed projection

T45 will implement deterministic packaging and cryptographic verification. The signed manifest digest is SHA-256 over the canonical UTF-8 JSON projection of the manifest with only `signedManifestDigest` and `signatureBase64` omitted. The projection therefore binds lifecycle, approval, signing algorithm, key ID, signing time, payload digest, provenance, compatibility, and all three evidence objects. Array order is preserved. Object keys are sorted recursively by ordinal code-point order.

T44 validates signature metadata syntax only. It does not claim that a signature is cryptographically valid, that a declared runtime is actually compatible, or that a payload exists. Those checks remain release gates for T45 and the runtime/storage integration slices.
