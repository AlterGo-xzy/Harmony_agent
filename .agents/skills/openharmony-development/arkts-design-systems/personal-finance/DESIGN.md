# Personal Finance Design System

## Intent
Use this pack for budget, expense categories, goals, spending overview, and transaction review. The app should feel trustworthy finance, personal, and complete on the first screen.

## Fixed Target
- Device: `1080×2340`, density `480`, device type `Phone`.
- Evidence screenshots must be app-only canvas backing bitmaps at exactly `1080×2340`.
- Design dimensions in ArkUI should be density-aware viewport units for this phone target. Do not use raw 1080 physical pixels as component widths or the UI will render about 3x too large.
- Optimize for single-file dynamic ArkTS under `<3000 LOC`.

## Visual Direction
- Background uses `DS_BG`; cards use `DS_SURFACE`; grouped regions use `DS_PANEL`.
- Use `DS_PRIMARY` for selected states and primary controls, `DS_ACCENT` for highlights, and `DS_SUCCESS` for completion/progress.
- Keep typography large, high-contrast, and sparse enough to read on a physical phone.
- Prefer calm composition and strong state color over decorative imagery.

## Required Screens
Home, Transactions, Goals, Profile, Transaction Editor.

## Component Patterns
Use balance cards, transaction rows, category bars, goal progress. Copy from `tokens.ets` and `components.ets` rather than inventing one-off geometry.

## Interaction States
Every visible primary control must produce one of: selected state, editor/sheet, toast text, list update, progress update, completed/open toggle, or disabled/demo feedback.

## Anti-Patterns
- No network images or mandatory video/media APIs.
- No tiny browser-form controls or oversized system-looking buttons.
- No bottom navigation floating above a large empty footer.
- No clipped text, overlapping chips, or uncapturable CSS-scaled screenshots.


## Open Design Package Contract
This pack follows the ArkTS-native Open Design-inspired contract: `manifest.json` is machine-readable discovery metadata, `USAGE.md` is the agent-facing generation guide, `DESIGN.md` is the visual and UX quality bar, and `tokens.ets` / `components.ets` provide previewer-safe ArkUI patterns.

## App Archetypes
- `budget tracker`
- `spending overview`
- `savings goals`
- `subscription review`

## Required States
- `empty`
- `selected period`
- `income`
- `expense`
- `goal progress`
- `editing`
- `toast`

## Quality Gates
- app-only screenshot is exactly 1080x2340 at density 480 Phone
- first screen communicates the product purpose without external explanation
- bottom navigation is anchored near the bottom with only a small home-indicator gap
- content is not hidden by navigation and no large empty footer remains
- icons, labels, search/add controls, and circular actions are centered in fixed containers
- every visible primary control has visible feedback and appears in the scenario test plan
- text is readable, unclipped, non-overlapping, and not dependent on network assets
- implementation stays single-file dynamic ArkTS friendly and under 3000 LOC unless user asks otherwise
