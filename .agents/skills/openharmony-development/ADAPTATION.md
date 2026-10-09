# Environment adaptation

This package is derived from the user-provided ArkTS Agent Kit and packaged as one portable skill. Supporting workflows are references, not separately installed skills.

These rules override supporting workflow files when there is a conflict:

1. **Support-file loading:** references to a repository `Read` tool mean opening the named bundled support file. No particular tool name is required.
2. **Nested workflows:** references to a nested skill mean reading its `WORKFLOW.md`. Only the package-root `SKILL.md` is installed.
3. **Reviewers:** an independent reviewer is optional. Use one only when the current surface supports and authorizes delegation. Otherwise perform a bounded same-agent review and label it non-independent.
4. **Build tools:** prefer the project's checked-in launcher or the installed DevEco/Hvigor toolchain. `arkui-hvigor`, `arkui-sign`, `arkui-device-cli`, and similar ArkTS Agent Kit wrappers are optional, never prerequisites.
5. **Omitted helpers:** if a referenced script or workflow is absent, use the documented manual check or an available native tool. Do not invent the missing helper or its output.
6. **External services:** this skill does not require or authorize external API keys or network calls merely because the upstream repository had helper tooling. Use external services only when independently available and appropriate to the user's request.
7. **Actual project/compiler wins:** when a bundled example differs from the user's installed SDK, compiler, project declarations, or diagnostics, use the actual project/compiler evidence and report the mismatch.
8. **Verification language:** no compile, lint, launch, device, previewer, screenshot, interaction, or runtime pass may be claimed without actual evidence from the current environment or user-provided output.
9. **Authorization boundary:** do not install dependencies, change global configuration, delete caches, terminate processes, sign packages, deploy to devices, or use network services unless the user's request and current permissions authorize that action. Resolve exact targets before destructive operations.
