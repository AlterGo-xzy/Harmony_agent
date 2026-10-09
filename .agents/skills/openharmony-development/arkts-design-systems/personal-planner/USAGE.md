# Personal Planner Usage

Use this design system when the user asks for daily planning, schedule, focus blocks, and task review. Treat it as an ArkTS-native generation package: load `manifest.json`, then `DESIGN.md`, then copy/adapt the constants and snippets from `tokens.ets` and `components.ets`.

## Generation Contract
- Target only `1080×2340`, density `480`, device type `Phone`.
- Build a self-contained single-file dynamic ArkTS app by default.
- Keep the generated app under `<3000 LOC` unless the user explicitly asks for a larger project.
- Use no backend, no network assets, no required video/media APIs, and no external image files by default.
- Prefer compact ArkUI viewport units; never size UI elements as raw 1080 physical pixels.
- Start from a product screen, not a debug form.
- Declare one style token set before coding: content width, screen padding, card radius, row radius, pill radius, CTA height, nav height, icon box size, and typography scale.
- Reuse those tokens across onboarding and all main tabs. Do not mix one-off primary widths, radii, CTA heights, or typography scales.
- For critical CTAs and navigation controls in dynamic ArkUI, keep the `.onClick` handler directly on the rendered `Row`, `Stack`, or `Text` control unless a callback-based builder has previewer evidence. Shared visual constants are good; opaque action callbacks in helper builders can hide dead controls from source review.

## Recommended Archetypes
- `daily planner`
- `calendar schedule`
- `weekly review`
- `focus tracker`

## Required UX States
- `title`
- `empty`
- `selected`
- `editing`
- `saved`
- `deleted`
- `done`
- `focus-running`
- `toast`

## Scenario Plan Requirements
Every generated app must include a scenario plan before implementation and every visible primary control must appear in it. Cover: launch state, all tabs or major sections, every sheet/modal, create/edit/save/cancel/delete where relevant, selected/toggled states, empty/demo feedback, chart/summary updates, and a final app-only screenshot at `1080×2340`.

Before verification, inventory source controls and chart/summary surfaces against the scenario plan. Use `scripts/arkts_ui_scenario_inventory.py` only when it is actually available; otherwise perform the inventory from source and record it manually.

Before visual QA, inventory the style tokens and reconcile them with the design-system contract. Use `scripts/arkts_ui_style_inventory.py` only when available; otherwise inspect the source and screenshots directly.

For personalized health/planning flows, do not group input controls. Goal amount, units, availability, gym access, meal preference, dog walk, reminder/settings, and chart tabs each need their own scenario row. Each row must prove both local feedback and at least one promised downstream planning change.

## Stateful Data Contract
- Classify every displayed number or status as editable in-memory state, derived state, or fixed demo estimate.
- Editable data must visibly update where it is edited and propagate to a summary, chart, calendar, or review screen when the app promises progress tracking.
- Availability and preference data must propagate to generated plan, overview, calendar schedule, and settings summary when those screens exist.
- Units and measurement data must propagate to all displayed measurement labels, not only the input page.
- Calendar and checklist data must be keyed by selected day. Do not use one global checklist or one global daily-data object when the UI lets the user switch dates. Verification must include: change day A, switch to day B, verify different state, switch back to day A, verify restoration.
- Calendar screens must be useful, not decorative: show live/current date context, selected-day summary, saved/draft status, schedule consequences, and progress/checklist state for the selected day.
- Date surfaces must be routed through a runtime date provider such as `currentDate()` or `nowMillis`; fixed visible dates are allowed only when the UI clearly says they are sample data.
- Fixed demo estimates must be labeled or framed as estimates; do not present them as live user data.
- Charts, progress graphs, and totals must either read from editable state or be clearly presented as fixed sample estimates.
- Settings such as goals, units, reminders, and preferences must update labels or open a real editor; toast-only settings rows are not sufficient.
- Settings rows with chevrons must navigate to real editors. Toggle settings such as meals, notifications, and units should use inline state pills and direct visible feedback instead of chevrons.
- Rows that look tappable must visibly change a label/value, navigate, open an editor/sheet, or show a clear status response.

## Visual Direction
Warm ivory background, ink text, deep green selected states, lime progress accents, compact rounded task cards, and a tab bar anchored near the phone bottom.

## Gold Standard Planner Flow
Use this pack as the first reference when improving the other design systems. Generate the planner flow as a coherent product loop: title or first-use state, Home task list, Calendar schedule, Overview progress, Profile/settings, and an editor sheet. The plus/create control must open the editor without freezing, Save must mutate visible in-memory task data, Cancel/Close must dismiss without mutation, Delete must remove or visibly mark the selected item, and each bottom tab must preserve centered icon/label geometry.

## Anti-Patterns
- Do not use CSS/web mental models, browser-form controls, or oversized system buttons.
- Do not leave the bottom navigation floating high above a blank footer.
- Do not hide content behind navigation or clip labels/chips.
- Do not claim functionality without visible feedback and click-through evidence.
- Do not mark a scenario passed from source inspection or unchanged screenshots.
- Do not let a happy-path scenario matrix skip secondary controls such as units, metric +/- controls, chart tabs, settings rows, or generated-plan edit paths.
- Do not let a functional pass hide visual-system drift. Inconsistent styling across screens is a verification failure, not a polish note.
