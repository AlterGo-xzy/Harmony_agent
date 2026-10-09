# Toolchain and startup

Use this when a build or runtime may be using the wrong project root, module, configuration, dependency graph, artifact, or entrypoint.

## Choose the build surface

Prefer the project's native documented command. For Windows/DevEco projects, read `../../../references/windows-deveco-development.md` and verify the DevEco SDK and Hvigor launcher paths before use. Optional ArkTS Agent Kit wrappers can be used when present, but are not mandatory.

For a multi-module project or code importing a local HAR, use the relevant project/module build. An isolated `.ets` compilation cannot validate the complete dependency graph and may produce misleading import cascades.

## Structural loop

1. Record the absolute project root, module, product, target, source root, and expected artifact.
2. Read the root and module build profiles plus the relevant `hvigorfile.ts`.
3. Compare the failing layout or entrypoint with a known-good module in the same project when available.
4. Run the narrowest native build from the proven root.
5. Do not edit unrelated source until the structural fact is established.

Entrypoint guidance: `../20-references/24-entrypoints-and-startup.md`.

## Common failures

### Configuration not found

Confirm the working directory and the configuration path expected by the selected launcher. Do not copy configuration files into guessed locations.

### Source exists but the build cannot see it

Confirm the module source root, target, product, dependency declarations, and the project root actually used by the tool.

### Runtime enters the wrong code path

Identify the actual ability, page, startup function, or symbol invoked by the runtime before editing application logic.

### Entry signature is rejected

Compare the installed SDK declaration and a working project example with `24-entrypoints-and-startup.md`. Avoid speculative overloads.

### Import/export failure may be a layout problem

Prove the written import, resolver root, module dependency, package export, and alias mapping before renaming symbols.

### JSON import fails

Use a pattern supported by the current project and SDK, such as typed ArkTS configuration or bundled raw resources parsed into an explicit type. Keep JSON imports only when the current build accepts them.

### Many diagnostics appear after one root error

Fix the first diagnostic that identifies the wrong call, missing module, or invalid configuration, then rerun the same check before touching cascade errors.

### HAP/HAR build fails before compilation

Separate environment setup, dependency resolution, signing, and source compilation. Do not run dependency installation, SDK downloads, or persistent configuration changes without authorization.

### Previewer or device launch fails

Treat build, signing, installation, launch, first render, and interaction as separate evidence boundaries. Use the available DevEco, previewer, or device tools; never claim later stages from build success alone.

## Cleanup

Prefer a native clean task. If cache deletion is necessary, resolve the exact absolute targets under the project root, preview them, and follow the current authorization rules. Never issue recursive deletion against unresolved relative paths, wildcards, a workspace root, or a user profile.

## Verify

- expected build task completed;
- expected artifact exists and is newer than its relevant inputs when that comparison is meaningful;
- runtime evidence identifies the intended entrypoint when runtime verification was performed;
- unverified signing, launch, UI, or device stages remain explicitly pending.

Return to `../WORKFLOW.md` after the structural fact is established.
