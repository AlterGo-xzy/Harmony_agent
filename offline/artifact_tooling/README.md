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

The signed manifest digest is SHA-256 over the canonical UTF-8 JSON projection of the manifest with only `signedManifestDigest` and `signatureBase64` omitted. The projection therefore binds lifecycle, approval, signing algorithm, key ID, signing time, payload digest, provenance, compatibility, and all three evidence objects. Array order is preserved. The defined package and manifest keys are sorted recursively before serialization.

T44 validates signature metadata syntax only. It does not claim that a signature is cryptographically valid, that a declared runtime is actually compatible, or that a payload exists.

## T45 pack and verify

`artifact-tool.mjs` creates one canonical JSON package containing the finalized manifest and the payload as canonical base64. It uses only Node built-ins. Packaging computes the raw payload SHA-256, signs the canonical manifest projection with Ed25519, writes through a completed same-directory temporary file, and publishes it with an atomic rename. The Windows tool rejects an existing output before publication and does not overwrite it.

```powershell
node offline\artifact_tooling\artifact-tool.mjs pack `
  --manifest <approved-manifest-input.json> `
  --payload <artifact-payload> `
  --private-key <external-ed25519-private-key.pem> `
  --key-id <trusted-key-id> `
  --output <new-artifact-package.json>

node offline\artifact_tooling\artifact-tool.mjs verify `
  --package <artifact-package.json> `
  --public-key <trusted-ed25519-public-key.pem> `
  --expected-key-id <trusted-key-id>
```

The tool never prints key material or payload content. Key provisioning, protection, rotation, and revocation remain external host responsibilities. The verifier rejects non-canonical packages, unknown fields, payload digest drift, manifest digest drift, non-Ed25519 keys, invalid signatures, and unexpected key IDs. Successful output contains identities and digests only.

Run the deterministic self-test into a new workspace evidence directory:

```powershell
node offline\artifact_tooling\test-artifact-tooling.mjs --output artifacts\t45-artifact-tooling\<new-run>
```

The self-test generates one transient Ed25519 key pair, proves repeated packaging with the same inputs and key is byte-for-byte identical, exercises both CLI commands, and rejects payload/manifest/signature/key-ID tampering and output overwrite. It retains only the fixture package, its public key, and a digest-only report; after deleting the private key and all other transient files, it verifies the retained package again. Actual runtime compatibility evaluation and Runtime/Storage lifecycle integration remain later S7 gates.
