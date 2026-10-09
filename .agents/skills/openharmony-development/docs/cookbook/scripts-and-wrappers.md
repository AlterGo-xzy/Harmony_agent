# Scripts And Wrappers

This repo exposes two different command surfaces:

- public user-facing commands for ArkTS developers
- maintainer-only commands for refreshing and validating the kit itself

## Public User-Facing Commands

These commands should rely only on:

- local guides and cards in `docs/`
- local examples
- the `arkts-*` / `arkui-*` console scripts (installed by bootstrap; on `PATH` after install)
- installed ArkTS tool binaries discovered through the local install state

Public skills must not resolve SDK or source paths themselves. Bootstrap writes the runtime binding into install-state, and wrappers consume that binding.

### Install And Verify

- `.venv/bin/arkts-bootstrap --adapter <runtime>`
  Canonical packaged bootstrap entrypoint after the first install.

- `arkts-agent-kit skills status --adapter <runtime> --workspace .`
  Read-only public-skill status report.
  Use it to confirm the resolved skills directory, which managed public skills are installed, whether they match the current repo revision, and whether stale or foreign skill directories exist.

- `arkts-compile examples/minimal/hello.ets --json`
  Compile the canonical install smoke-test file.

- `arkts-lint examples/minimal --json`
  Lint the enclosing sample directory.
  Use these two commands together as the install smoke test for the primary non-UI developer loop.

### ArkTS Work Wrappers

- `arkts-compile <file.ets> --json`
  Compile one ArkTS file with the configured local toolchain.
  Plain ArkTS files use `es2panda`. ArkUI `@Entry` and `@Component` files route to the upstream build-system when that capability is installed.
  For plain static ArkTS frontend triage, start with a known-good file or module from the same project.
  The JSON payload is normalized for skill-time consumption and omits raw debug command details unless the wrapper needs to surface fallback raw output.

- `arkts-lint <path> --json`
  Run the ArkTS linter on a file or directory.
  For file targets, the wrapper scans the containing directory internally and returns file-scoped results for the requested path.

- `arkts-check <file-or-dir> --json`
  Run the combined compile-and-lint loop. This is the default wrapper for `implement-arkts`.
  For file targets, compile still runs against the requested file while lint scans the containing directory internally and returns file-scoped results for the requested path.
  If a UI target cannot be compiled because the local upstream build-system is incomplete, the command reports a blocked compile phase with the missing capability instead of raw parser noise.

- `arkts-capabilities`
  Return the current wrapper capability snapshot for compile, lint, UI compile, and related local prerequisites.

- `arkts-lint <path> --fix --json`
  Apply bounded linter-backed fixes when safe local autofix is available.
  Use it only after the failure family is understood and compile is already green or intentionally skipped.

- `arkts-migrate --from typescript <path> --json`
  Return a source-scanned migration plan through the TypeScript profile.
  The JSON payload includes detected patterns, evidence, linked guide cards, linked before/after examples when local demos exist, and next steps.
  Some migration guides remain LLM-guided or diagnostics-guided instead of source-scanned; `migration/static-member-inheritance` is currently in that category.

- `arkts-migrate --from javascript <path> --json`
  Return a source-scanned migration plan through the JavaScript profile.
  The JSON payload includes detected patterns, evidence, linked guide cards, linked before/after examples when local demos exist, and next steps.

## Optional MCP Surface

The same wrappers are also available as an optional MCP server, `arkts_agent_kit_tools`,
which agents call as `mcp__arkts_agent_kit_tools__check`, `…__compile`, etc. The MCP tools
reuse the same library layer as these wrappers and return the **identical JSON contract**,
so the two surfaces are interchangeable — prefer the MCP tools when registered, otherwise
use the `arkts-*` / `arkui-*` console scripts. Install with `arkts-agent-kit mcp-tools install --adapter <runtime> --scope <global|project>`.
See `docs/cookbook/mcp-server.md` for the tool list and manual configuration.

## Advanced Direct CLI

Public skills and normal user workflows should use the `arkts-*` / `arkui-*` console scripts, not the Python CLI directly. The direct CLI entries below are for maintainer or low-level debugging work.

Not every public skill has a one-to-one console script. For example, `modernize-arkts`, `optimize-arkts`, and `review-arkts` are skill workflows that orchestrate the existing scripts rather than exposing separate shell commands.

Useful direct commands:

- `arkts-capabilities`
- `arkts-agent-kit check <path> --json`
- `arkts-agent-kit compile <path> --json`
Equivalent static compile shape on macOS:

```bash
DYLD_LIBRARY_PATH=<build-dir>/lib \
<build-dir>/bin/es2panda \
  /tmp/triage_min4.ets \
  --extension ets \
  --output /tmp/triage_min4.abc
```

Prefer `arkts-compile` during normal skill execution so the command stays tied to local install state instead of hardcoded paths.

## Maintainer-Only Commands

These commands may use live `arkcompiler_*` source trees and are not part of the default product workflow.

- `arkts-bootstrap maintainer --adapter <runtime> ...`
  Installs the maintainer bundle and validates live source access. Source-tree paths are passed with flags such as `--panda-sdk`, `--ohos-sdk`, `--interface-sdk-js`, and `--ace-ets2bundle`.

Maintainer artifact rule of thumb:

- `.generated/*` is local maintainer/runtime state and should not be treated as release content

## Update Workflow

Recommended update loop:

1. Pull the latest repo changes.
2. Re-run `arkts-bootstrap product --adapter <runtime>` for product mode or `arkts-bootstrap maintainer` for maintainer mode. Add `--force` only when resetting omitted path inputs.
3. Run `arkts-compile examples/minimal/hello.ets --json`.
4. Run `arkts-lint examples/minimal --json`.
5. Restart the runtime if refreshed global skills do not appear immediately.

Optional read-only confirmation:

- `arkts-agent-kit skills status --adapter <runtime> --workspace .`

Optional recurring automation guidance:

- Keep automation outside bootstrap itself.
- Schedule a repo pull, re-bootstrap, status check, and the same two smoke tests as external commands.

## Rule Of Thumb

- If the task is “install, bootstrap, upgrade, or verify the ArkTS kit for this workspace”, use `INSTALL.md`.
- If the task is “write, check, fix, modernize, optimize, review”, use `arkts-skills/`, `docs/`, and the `arkts-*` / `arkui-*` console scripts.
- For the normal developer loop, prefer:
  1. `arkts-check`
  2. `arkts-compile` when plain static `.ets` compile is the first failing signal
  3. `arkts-lint` when compile is already green
- If the task is “validate or publish the kit itself”, use `.agents/skills/` and maintainer-mode install.
