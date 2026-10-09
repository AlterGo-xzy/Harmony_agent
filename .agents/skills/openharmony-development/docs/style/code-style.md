# ArkTS Code Style

This repo treats style as part of reliability, not as a cosmetic pass.

## Style Priorities

- Prefer explicit types when they improve clarity or avoid ambiguous inference.
- Prefer simple class/interface contracts over clever dynamic patterns.
- Keep imports at the top of the file.
- Avoid unsupported decorators, dynamic object tricks, and source-language leftovers.
- Use warning-clean code when possible.

## Tool Coupling

- Linter and warning outputs are first-class style signals.
- When a style choice has a cookbook tag or fix recipe, cite it in reviews and migrations.
