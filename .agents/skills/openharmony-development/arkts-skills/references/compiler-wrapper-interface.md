# Build and compiler interface selection

Use the project's native build surface by default. ArkTS Agent Kit wrappers are optional adapters, not requirements.

## Selection order

1. Follow checked-in project documentation or launchers.
2. For Windows/DevEco projects, read `../../references/windows-deveco-development.md` and use the verified Hvigor launcher.
3. Use an optional wrapper or MCP tool only when it is actually registered and suitable for the project.
4. If no trustworthy build surface can be found, report verification as blocked and identify the missing tool or configuration. Do not compensate with speculative source rewrites.

## Available surfaces

| Situation | Preferred check |
|---|---|
| OHOS/HAP/HAR project | Native project Hvigor task from the project root |
| Multi-module project or local HAR import | Full relevant project/module task; do not rely on isolated-file compilation |
| Standalone `.ets` file | Available compiler/linter or an optional `arkts-check`/`arkts-compile` wrapper |
| Compile already green, policy/style review needed | Available project lint task or optional `arkts-lint` |
| Device build, signing, install, and launch | Separate authorized steps with evidence for each boundary |

When optional `arkts_agent_kit_tools` MCP tools or commands such as `arkts-check`, `arkts-compile`, `arkts-lint`, `arkui-hvigor`, or `arkui-device-cli` are present, their structured output can be useful. Do not assume they exist and do not invent their output.

## Boundaries

- A single-file compile cannot validate a project dependency graph.
- A project build does not prove signing, installation, launch, UI behavior, or device capabilities.
- Dependency installation, SDK downloads, persistent environment changes, signing, deployment, process termination, and cache deletion require the authorization appropriate to the current environment.
- Actual project declarations, installed SDK APIs, compiler diagnostics, and tool output override bundled examples.
