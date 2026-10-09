---
name: design-arkts-ui-app
description: Use when planning or generating a personalized ArkTS mobile UI app, selecting an Open Design-inspired ArkTS design-system package, choosing an app archetype, producing an implementation blueprint, or preparing end-to-end app generation before coding.
---

> Root `SKILL.md`, `ADAPTATION.md`, and `VERIFICATION.md` define the active environment, authorization, and evidence rules.


# design-arkts-ui-app

## Purpose
Extend `implement-arkts` for ArkUI app work by producing a decision-complete UI blueprint before coding. This skill plans the UI contract; it does not replace the general implementation loop, compile/repair loop, review gate, or finish criteria in `implement-arkts`.

Use this skill before `implement-arkts` only for mobile UI apps, demos, one-screen tools, personal trackers, games, dashboards, or any request where visual quality and interaction completeness matter.

## Output
Report:
- selected category and design system
- category confidence, selected archetype, and fallback rationale
- personalization assumptions inferred from the prompt
- app blueprint using the `references/blueprint-format.md` shape
- expected implementation file shape
- scenario test plan
- expected source-inventory coverage gates
- design-system quality gates
- styling consistency contract
- sleek/top-quality visual acceptance contract: what makes this UI modern, polished, cohesive, and human-acceptable

## Read First
- `references/design-principles.md` — mandatory base: component hierarchy, visual hierarchy, primary actions, spacing, state, color, reuse, touch targets, accessibility, and cross-size testing
- `arkts-design-systems/`
- `references/category-selection.md`
- `references/blueprint-format.md`
- `arkts-skills/references/ui-ux-quality-bar.md`

## Defaults
- Target: `1080×2340`, density `480`, device type `Phone`.
- Layout units: design ArkUI geometry in density-aware viewport units while still saving evidence screenshots at `1080×2340`; do not treat physical pixels as component widths.
- Runtime: static ArkTS. For app generation, prefer a Stage-model OHOS app/HAP when the user asks for an app; use a single `.ets` preview target only for small UI demos.
- Assets: no backend, no network images, no required video/media APIs by default. For production-sized local image catalogs, blueprint rawfile paths instead of generated `$r` switch tables.
- Personalization: infer names, categories, sample data, tone, and visual mood from the user prompt; if missing, choose safe personal defaults and record them.

## Workflow
1. Classify the request into the matching category from `references/category-selection.md`.
2. Load only the selected design-system pack: `manifest.json`, `DESIGN.md`, `USAGE.md`, `tokens.ets`, `components.ets`.
3. Produce a compact blueprint using the format from `references/blueprint-format.md`. At minimum name: app goal, screens and navigation, state model with mock data, control-to-state-to-downstream table for every editable input, primary controls with expected feedback, scenario test plan with per-control expected state changes and downstream surface effects, design-system quality gates, and a styling consistency contract.
4. Return the blueprint to `implement-arkts`. Implementation, compile/repair, review, and final reporting stay owned by `implement-arkts`.
5. After implementation and review, `implement-arkts` routes UI evidence through root `VERIFICATION.md`. Use the available authorized previewer or device surface and label unavailable runtime checks as pending.

## Blueprint Rules
- Follow the design principles in `references/design-principles.md`: component hierarchy, visual hierarchy, one primary action per section, grouped controls, spacing tokens, explicit state, semantic color, reusable components, touch targets with accessibility, and cross-size/theme testing.
- Require a sleek, top-quality, modern, cohesive UI that a human reviewer would accept. The blueprint must reject debug-form, sparse, generic, system-default, old-looking, cluttered, or visually unappealing screens as blockers, not polish.
- Keep the first screen immediately understandable.
- Use the manifest as a contract, not as loose inspiration. Follow `USAGE.md` for category-specific generation rules and `DESIGN.md` for visual judgment.
- Define one visual-system token set before implementation. The blueprint must name shared widths, card/row/CTA radii, CTA/nav heights, selected-state colors, typography scale, and spacing tokens (4/8/12/16/24/32). All main screens must share the same layout rhythm. Implementation must not rely on scattered one-off numeric styling.
- Include loading, empty, selected, disabled/demo, create/edit, and success states where relevant.
- Prefer 4 bottom tabs plus a sheet/editor over many screens.
- Use direct, tappable ArkUI controls with visible mock feedback.
- Every editable input must visibly affect the current screen and at least one downstream surface when the app promise implies progress, summary, or planning propagation. For category-specific inputs, use `USAGE.md` to decide which screens must change downstream. The blueprint must state exactly which surface changes after each editable input changes.
- Charts, progress graphs, totals, and summaries must be backed by state named in the blueprint or explicitly labeled as fixed demo estimates. Chart tabs must list their driving state fields and expected visible changes. If a chart is fixed, label it non-interactive/fixed estimate and do not style it as live progress.
- Settings rows must have a real visible result: change a label/value, navigate to a real editor, open a sheet, or be styled as non-tappable. Decorative rows must not look tappable. If a row looks tappable, it must change a visible value, navigate, open a sheet, or show a clearly visible status.
- A row that only changes `toastText` is `toast-only-control` unless the toast is the whole promised behavior.
- Fake/demo data must be declared as fixed demo estimates. Editable data must visibly affect the same screen and at least one downstream screen when the product promise implies propagation.
- Every stateful control must have two evidence layers when the product promise implies propagation: current-screen feedback and downstream surface feedback.
- Calendar/date surfaces must use the current real date or clearly explain that they are fixed sample dates. A stale date is `date-not-real` when the user story expects live planning.
- Reuse components: if three cards share the same structure, use one component with different data, not three separate handmade layouts.
- Supporting screens must feel like part of the same product, not leftover debug forms.
- Do not specify unsupported APIs or network dependencies unless the user explicitly asks.
- Do not invent a new design language when a selected pack provides tokens, snippets, archetypes, and quality gates.
- Define one visual-system token set before implementation. The blueprint must name shared widths, card/row/CTA radii, CTA/nav heights, selected-state colors, and typography scale. Implementation should not rely on scattered one-off numeric styling.
- Main app screens and onboarding screens must share the same shell rhythm unless the blueprint explicitly calls out a decorative exception.
- When a design-system manifest is provided, its `qualityGates` and `primaryControls` are mandatory audit input, not optional inspiration.

## Stop Conditions
Stop when the blueprint is decision-complete enough for `implement-arkts`, or when the user request truly conflicts with the fixed constraints and needs a product decision.
