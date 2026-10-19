# T51 follow-up fix review

## Result

The two P1 findings from the T51 rejection are addressed in a follow-up commit; the original commit fdc3cb506343a779bfe89cb9f1d74036940e06fb is not rewritten. The deterministic checker report digest is now `sha256:0f4367d6de077b0a6df712ff41d1e45af3681e7338f13cbe9973e8ee73440fa3`; the fail-closed suite passes 13/13.

## P1-1: strict JSON Schema validation

`check-masrouter-inputs.mjs` now contains a local, dependency-free validator for the schema subset used by the four contracts. It rejects unsupported schema keywords and enforces `type`, `required`, `additionalProperties`, `properties`, `items`, `minItems`, `maxItems`, `uniqueItems`, `minLength`, `minimum`, `maximum`, `pattern`, `const`, `enum` and local `$ref`.

The four input documents are validated before any manual invariant:

- `environment-candidates.json` against `schemas/environment-lock.schema.json`
- `dataset-lock.json` against `schemas/dataset-lock.schema.json`
- `model-pools.json` against `schemas/provider-model-lock.schema.json`
- `price-snapshot-candidate.json` against `schemas/price-snapshot.schema.json`

The checker now rejects the exact case from the rejection: adding an `unexpectedField` to `environment-candidates.json` fails with `schema validation failed at $.unexpectedField: additional property is not allowed`.

New negative tests cover unknown top-level field, unknown nested field, nested type error and missing required field. Test count is 13/13.

## P1-2: workspace-bound execution

- Test fixtures now use `D:\Harmony_agent\artifacts\t51-input-tests\run-*` and are removed on exit; `os.tmpdir()` is no longer imported or used.
- The re-run source audit used `D:\Harmony_agent\.local\t51-source-audit\work` and `tooling`; the archive was downloaded, verified and extracted only inside the workspace.
- The source audit directory and all test scratch directories were deleted after evidence capture; cleanup is recorded in `cleanup.txt`.
- No file was written to `C:\Users\Admin\AppData\Local\Temp` during this fix.

## Validation actually run

- `node offline/paper_repro/masrouter/check-masrouter-inputs.mjs --check`
  -> `sha256:0f4367d6de077b0a6df712ff41d1e45af3681e7338f13cbe9973e8ee73440fa3`
- `node offline/paper_repro/masrouter/test-masrouter-inputs.mjs`
  -> `Tests run: 13, Failure: 0, Error: 0, Pass: 13, Ignore: 0`
- JSON parse of 4 schemas + 7 input documents -> 11/11
- `git diff --check` -> exit 0 with line-ending warnings only
- staged-content secret-pattern scan -> no matches

## Evidence boundary

Completed: strict Schema validation, 13 fail-closed tests, workspace-internal source re-audit, deterministic report, updated docs and evidence.

Not run: dependency installation, dataset download, dataset digest computation, model download, credential reads, Provider calls, training, benchmark execution, ArkTS/Hypium, HAR/HAP build, signing, installation or device execution. T54 remains paused.

## Pre-existing worktree differences

The six pre-existing unstaged files were not modified, staged or committed by this fix.
