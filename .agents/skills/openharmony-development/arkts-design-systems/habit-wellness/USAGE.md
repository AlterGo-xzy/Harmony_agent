# Habit & Wellness Usage

Use this design system when the user asks for habits, wellness streaks, mood, water, sleep, and gentle health routines. Treat it as an ArkTS-native generation package: load `manifest.json`, then `DESIGN.md`, then copy/adapt the constants and snippets from `tokens.ets` and `components.ets`.

## Generation Contract
- Target only `1080×2340`, density `480`, device type `Phone`.
- Build a self-contained single-file dynamic ArkTS app by default.
- Keep the generated app under `<3000 LOC` unless the user explicitly asks for a larger project.
- Use no backend, no network assets, no required video/media APIs, and no external image files by default.
- Prefer compact ArkUI viewport units; never size UI elements as raw 1080 physical pixels.
- Start from a product screen, not a debug form.

## Recommended Archetypes
- `habit streak tracker`
- `wellness dashboard`
- `daily check-in`
- `sleep and water log`

## Required UX States
- `empty`
- `selected`
- `checked`
- `missed`
- `streak`
- `editing`
- `toast`

## Scenario Plan Requirements
Every generated app must include a scenario plan before implementation and every visible primary control must appear in it. Cover: launch state, all tabs or major sections, every sheet/modal, create/edit/save/cancel/delete where relevant, selected/toggled states, empty/demo feedback, and a final app-only screenshot at `1080×2340`.

## Visual Direction
Fresh wellness palette, rounded progress rings or bars, friendly check-in cards, soft success states, and calm spacing.

## Anti-Patterns
- Do not use CSS/web mental models, browser-form controls, or oversized system buttons.
- Do not leave the bottom navigation floating high above a blank footer.
- Do not hide content behind navigation or clip labels/chips.
- Do not claim functionality without visible feedback and click-through evidence.
