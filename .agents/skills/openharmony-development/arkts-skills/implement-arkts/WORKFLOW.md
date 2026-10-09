---
name: implement-arkts
description: Implement ArkTS and ArkUI changes with project-aware routing, native builds, diagnostics, review, and evidence-based verification.
---

# Implement ArkTS

Use this workflow for code changes. Root `SKILL.md` and `ADAPTATION.md` define the environment and authorization boundaries.

## Read first

- `arkts-skills/arkts-skill/WORKFLOW.md`
- the narrowest specialist route named by that workflow
- `references/windows-deveco-development.md` for Windows/DevEco/Hvigor projects
- `arkts-skills/references/ui-ux-quality-bar.md` only when a user-facing ArkUI surface changes

## Establish the target

1. Inspect the user request, relevant source, nearby tests, project profiles, module configuration, SDK declarations, and existing build instructions.
2. Record a compact route ledger: `touched surface -> specialist reference -> planned check`.
3. Identify the smallest useful evidence target: source check, HAR build, HAP build, test, previewer scenario, or device scenario.
4. Separate required behavior from optional polish. Do not turn an implementation request into an unrequested migration, dependency upgrade, or project-wide rewrite.

## Implement

1. Read the specialist reference before editing that API or UI surface.
2. Follow existing project conventions unless they conflict with the compiler, installed SDK declarations, or the user's requirement.
3. Make the smallest coherent change that delivers real behavior. Do not replace requested functionality with hard-coded results, decorative controls, or fake live data. Mark unavoidable stubs explicitly.
4. When a new API surface appears, add it to the route ledger and read its specialist reference before continuing.
5. Check explicit types, nullability and narrowing, class/interface shape, imports, state ownership, lifecycle cleanup, permissions, resource use, and error handling where relevant.

## Build and repair

1. Prefer a checked-in project command. Otherwise use the installed DevEco/Hvigor launcher described in `references/windows-deveco-development.md` after verifying its path.
2. Optional wrappers such as `arkts-check` or `arkui-hvigor` may be used when actually present, but their absence is not a blocker if the native project toolchain is available.
3. For multi-module projects and local HAR imports, use the project build graph rather than an isolated single-file compile.
4. On failure, classify the first actionable diagnostic with `arkts-skills/references/diagnostic-classification.md` and the matching diagnostic or fix card. Repair that blocker and rerun the same narrow check.
5. Do not install dependencies, modify global SDK settings, change signing configuration, or delete caches without authorization. Do not widen into unrelated edits when a build environment is incomplete.

## Review

After the requested slice is coherent, read `arkts-skills/review-arkts/WORKFLOW.md` and perform a bounded review. Use an independent reviewer only when delegation is available and authorized; otherwise do a same-agent review and label it non-independent.

Blocking findings are correctness, data-loss, security, explicit requirement, compile, launch, or demonstrated accessibility failures. Treat subjective polish as deferred unless the user explicitly requested presentation-ready UI.

## UI and device verification

For ArkUI or device-capability work, follow `VERIFICATION.md`.

- Build success does not prove launch, rendering, interaction, permission, sensor, network, or device behavior.
- Use screenshots, logs, UI trees, previewer output, or device results only when actually available.
- If direct runtime access is unavailable, provide the narrowest user-run procedure and report verification as pending rather than failed.

## Finish

Report:

- files and behavior changed;
- route references used;
- exact checks run and their observed results;
- whether review was independent or same-agent;
- what remains unverified and the next concrete verification action;
- SDK, permission, device, signing, or environment risks still open.

Stop when the requested behavior is implemented and the available proportionate checks pass, or when the first concrete external blocker is documented. Missing optional wrappers or subagents alone are not blockers.
