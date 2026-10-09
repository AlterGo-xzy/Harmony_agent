# Guide Usage

Use authored guidance in this order:

1. `docs/cards/*`
2. `docs/diagnostics/*`
3. `docs/curated/*`
4. `docs/language`, `docs/migration`, `docs/cookbook`, and `docs/style`

Runtime guide routing reads card frontmatter directly. Skills should select cards by `related_skills`, `related_diagnostics`, and `related_migration_patterns`.

For exact APIs, inspect available SDK declarations and confirm behavior with the wrappers. Do not invent signatures when local documentation does not specify them.
