# Personal Planner Design System

## Intent
Use this pack for daily planning, schedule, focus blocks, and task review. The app should feel calm productivity, personal, and complete on the first screen.

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
Home, Calendar, Overview, Profile, Editor.

## Component Patterns
Use planner cards, day chips, schedule blocks, progress bars. Copy from `tokens.ets` and `components.ets` rather than inventing one-off geometry.

## Styling Consistency Contract
- Declare and reuse one token set for content width, screen padding, card radius, row radius, pill radius, CTA height, nav height, icon box size, and typography scale.
- Onboarding and main tabs must share the same shell rhythm: status/header, content width, card spacing, CTA geometry, and bottom-safe-area behavior.
- Primary cards use the same width, radius, and padding. Primary rows use the same row height/radius unless a chart or calendar cell requires a named exception.
- Primary CTAs use one centered pill style. Avoid mixing top pill buttons, full-width buttons, pale pseudo-buttons, and manually padded labels as separate visual systems.
- Bottom nav icons and labels must sit in fixed containers with centered glyphs and consistent selected state.

## Interaction States
Every visible primary control must produce one of: selected state, editor/sheet, toast text, list update, progress update, completed/open toggle, or disabled/demo feedback.

## Anti-Patterns
- No network images or mandatory video/media APIs.
- No tiny browser-form controls or oversized system-looking buttons.
- No bottom navigation floating above a large empty footer.
- No clipped text, overlapping chips, or uncapturable CSS-scaled screenshots.
- No unexplained style drift: mixed content widths, multiple competing primary radii, ad hoc CTA heights, or screen-specific typography without a declared exception.


## Open Design Package Contract
This pack follows the ArkTS-native Open Design-inspired contract: `manifest.json` is machine-readable discovery metadata, `USAGE.md` is the agent-facing generation guide, `DESIGN.md` is the visual and UX quality bar, and `tokens.ets` / `components.ets` provide previewer-safe ArkUI patterns.

## App Archetypes
- `daily planner`
- `calendar schedule`
- `weekly review`
- `focus tracker`

## Required States
- `title`
- `empty`
- `selected`
- `editing`
- `saved`
- `deleted`
- `done`
- `focus-running`
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
- style inventory check passes with no unexplained primary width/radius/CTA/nav/token drift

## Gold Standard Notes
Use this pack as the reference implementation style for new ArkTS design systems. A strong planner app should open with a finished product surface: status row, greeting, compact day/focus summary, tappable task cards, and a bottom navigation bar that visually belongs to the phone shell. Calendar and overview screens should feel like sibling screens, not separate prototypes: reuse card radii, chip sizing, selected-state colors, and fixed icon containers. The editor should be a bottom sheet with visible save/cancel/delete feedback and should never freeze after the create action.
