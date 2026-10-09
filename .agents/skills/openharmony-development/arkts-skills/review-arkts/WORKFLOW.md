---
name: review-arkts
description: Run bounded quality review for an ArkTS change set using requirements, project evidence, and available verification results.
---

# Review ArkTS

## Purpose

Review a coherent ArkTS change set for issues that change the next safe action. The current agent may perform the review. Use an independent reviewer only when delegation is available and authorized, and label which mode was used.

## Inputs

- user request and acceptance criteria;
- changed files, patch, or diff;
- relevant project configuration and route ledger;
- compile, build, test, launch, screenshot, or device evidence that actually exists.

## Workflow

1. Confirm the review scope and identify missing evidence. Review can still find source-level issues when runtime evidence is unavailable; mark runtime conclusions pending instead of blocking the review itself.
2. Read `arkts-skills/arkts-skill/WORKFLOW.md` and the specialist references for risky touched surfaces.
3. Check requirements and real behavior before style:
   - correctness, data loss, security, permissions, lifecycle, cleanup, and error paths;
   - feature completeness, including whether visible controls have their promised effects;
   - state and data flow, API/import/signature compatibility, and bounded change scope;
   - compiler, build, test, runtime, and UI evidence gaps;
   - accessibility and interaction basics for changed UI.
4. Use `arkts-skills/references/ui-ux-quality-bar.md` when presentation quality is part of the request. Do not turn subjective visual taste into a release blocker for ordinary maintenance work.
5. Separate findings into:
   - blocking: correctness, data-loss, security, explicit requirement, compile, demonstrated runtime, or demonstrated accessibility failures;
   - deferred: non-blocking maintainability and optional polish;
   - unverified: claims requiring unavailable build, runtime, previewer, device, or user evidence.
6. Keep the pass bounded. After a blocker is fixed, re-check the fix and directly affected behavior rather than restarting a project-wide review.

## Output

- pass, fail, or source-review-complete/runtime-pending;
- blocking findings with exact file and line references plus the next safe action;
- deferred findings and unverified items separately;
- route references and evidence used;
- whether the review was independent or same-agent;
- residual risks.
