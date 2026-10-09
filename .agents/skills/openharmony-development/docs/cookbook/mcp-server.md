# ArkTS Tools MCP Server

The kit ships an optional Model Context Protocol (MCP) server, `arkts_agent_kit_tools`,
that exposes the same ArkTS toolchain as the `arkts-*` / `arkui-*` console scripts — `compile`,
`check`, `lint`, `migrate`, `capabilities`, `hvigor`, `sign`, previewer and device
tools — as MCP tools. Agents call them as `mcp__arkts_agent_kit_tools__check`,
`mcp__arkts_agent_kit_tools__compile`, and so on.

MCP is **optional**. The console scripts remain the default; the MCP tools return the
**same JSON contract** (`ToolReport`), so the two surfaces are interchangeable. Prefer
the MCP tools when they are registered; otherwise use the `arkts-*` / `arkui-*` console scripts.

The server binary is `arkts-agent-kit-mcp-tools`. It is purely a stdio MCP server — it
does not accept the `check`/`compile`/… subcommands (those stay on `arkts-agent-kit`).

## Install with the CLI (recommended)

```bash
arkts-agent-kit mcp-tools install   --adapter <codex|claude-code|opencode> --scope <global|project> [--workspace PATH]
arkts-agent-kit mcp-tools status     --adapter <...> --scope <...>
arkts-agent-kit mcp-tools uninstall  --adapter <...> --scope <...>
```

- `--scope project` writes into the workspace (`--workspace`, defaults to the current
  directory); `--scope global` writes into the runtime's user config.
- `install` **merges** into the existing config, preserving any other MCP servers and
  settings; `uninstall` removes only the `arkts_agent_kit_tools` entry.
- The registered launch command is resolved from the installed console script, so it is
  correct for both a local `.venv` and a global `uv tool install`.

The installer just automates the manual snippets below — the two paths are equivalent.

## Manual configuration

Resolve the server path once:

```bash
command -v arkts-agent-kit-mcp-tools   # e.g. /path/.venv/bin/arkts-agent-kit-mcp-tools
```

Then register `arkts_agent_kit_tools` in your runtime's config. `<CMD>` below is that path.

### claude-code — JSON

Project: `<workspace>/.mcp.json` · Global: `~/.claude.json`

```json
{
  "mcpServers": {
    "arkts_agent_kit_tools": {
      "type": "stdio",
      "command": "<CMD>",
      "args": []
    }
  }
}
```

### opencode — JSONC

Project: `<workspace>/.opencode/opencode.jsonc` · Global: `$XDG_CONFIG_HOME/opencode/opencode.jsonc` (else `~/.config/opencode/opencode.jsonc`)

```jsonc
{
  "mcp": {
    "arkts_agent_kit_tools": {
      "type": "local",
      "command": ["<CMD>"],
      "enabled": true
    }
  }
}
```

### codex — TOML

Project: `<workspace>/.codex/config.toml` · Global: `$CODEX_HOME/config.toml` (else `~/.codex/config.toml`)

```toml
[mcp_servers.arkts_agent_kit_tools]
command = "<CMD>"
args = []
```

> **Codex trust note:** project-scoped `.codex/config.toml` is loaded only for **trusted**
> projects, and is merged additively on top of the global config. If you keep the project
> untrusted, install into the global `~/.codex/config.toml` instead.

## Tools

| MCP tool | Shell wrapper equivalent |
|----------|--------------------------|
| `check`, `compile`, `lint`, `migrate`, `capabilities` | `arkts-check`, `arkts-compile`, `arkts-lint`, `arkts-migrate`, `arkts-capabilities` |
| `hvigor`, `sign` | `arkui-hvigor`, `arkui-sign` |
| `preview_show`, `preview_start`, `preview_stop` | `arkui-preview` |
| `build_library`, `build_app`, `run_app` | `arkts-build-library`, `arkts-build-app`, `arkts-run-app` |
| `device_cli`, `preview_cli` | `arkui-device-cli`, `arkui-preview-cli` |

Every path argument resolves against the server's working directory (the workspace the
runtime launches it in); pass the optional `workspace` argument to override per call.
