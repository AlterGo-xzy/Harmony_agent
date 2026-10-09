# ArkTS UI/UX Quality Bar

Use this reference with root `VERIFICATION.md` when judging or improving ArkTS app visual quality, interaction design, or presentation readiness. It adapts general mobile-design, accessibility, and usability principles to ArkUI work. Apply the requested product quality bar and distinguish build, render, interaction, and real-device evidence.

Sources:
- Apple UI Dos and Don'ts: https://developer.apple.com/design/tips/
- Material Accessibility: https://m1.material.io/usability/accessibility.html
- WCAG 2.2: https://www.w3.org/TR/wcag/
- NN/g Heuristics Summary: https://media.nngroup.com/media/articles/attachments/Heuristic_Summary1_A4_compressed.pdf

## Visual Acceptance — Hard Subjective Gate

This is the single most important gate. Technical correctness means nothing if the app looks bad.

- **The required UI outcome is sleek, top-quality, modern, cohesive, and desirable.**
- **Reject as blocking any UI that is functional but ugly, stale, sparse, generic, system-default, old-looking, cluttered, visually incoherent, amateurish, or unlikely to be accepted by a human reviewer.** Leniency here is itself a failure mode — if the agent thinks "it works" and calls it PASS, but a person looking at the screenshot would wince, the review is broken.
- **Subjective-dislike is a hard FAIL.** If the agent, after reviewing a screenshot, feels any sense of "this doesn't look good," "this looks cheap," "I wouldn't want to use this," or "a designer would reject this," the verdict is FAIL. Do not rationalize away ugliness with functional correctness. Ugliness IS a correctness failure for UI products.
- **Anti-patterns that are instant FAIL regardless of any other quality:**
  - **Text-wall screens**: screens with nothing but plain colored text rows, no cards, no images, no structural containers. Looks like a terminal, not a mobile app.
  - **Raw-default components**: unstyled system buttons, unstyled system lists, standard white/black default colors with no theme. Looks like a Hello World tutorial, not a product.
  - **Spreadsheet layout**: uniform grid of identical small cells with no hierarchy, no focal point, no primary action. Looks like a debug tool, not an app.
  - **Gray-desert**: screen dominated by a single shade of gray/dark with no accent colors, no visual anchors, no depth. Looks unfinished.
  - **Tiny-touch-target hell**: controls below 40px in any dimension that aren't inline text links. Feels hostile on mobile.
  - **Floating orphan elements**: controls not contained in cards, panels, or bars that appear to be accidentally placed in blank space.
  - **Typography soup**: four or more text sizes in close proximity with no deliberate scale, creating visual noise instead of hierarchy.
- The first screen must immediately communicate the app category, content, and primary action. A user who sees the first screen for 2 seconds should know what the app is and what to do next.
- If a selected ArkTS design-system pack is available, audit against its manifest `qualityGates`, `requiredScreens`, `requiredStates`, and `primaryControls`.
- Treat `DESIGN.md` as the visual bar and `USAGE.md` as the generation contract for that category.
- Avoid debug-form UI in presentation demos: oversized system buttons, unstyled lists, sparse blank panels, and generic labels are blocking findings unless the user explicitly requested a raw debug tool.
- Text must remain readable, unclipped, and non-overlapping at every target size.
- Use clear hierarchy: one primary focus per screen, compact supporting controls, and enough spacing to scan quickly.
- Brightness and contrast must survive realistic device glare. If a real-device photo looks muddy, increase luminance contrast, simplify overlays, and use stronger accent panels.
- Do not rely on network images for offline previewer demos unless the app has explicit permission handling and visible fallbacks.
- **Every screen must have at least one "I designed this" moment** — a deliberate visual choice (color accent, card shape, icon treatment, typography pairing, spacing rhythm) that signals intentional craft. Screens where every element looks like the first default from the component library are not designed; they are assembled. Assembly is not enough.

## Proportion, Spacing, and Sleekness
- **No element may visually dominate the screen without clear product intent.** A bottom button occupying over 12% of screen height, a hero image eating over 40% of the viewport, or a header consuming more than 15% are blocking `proportion-violation` findings unless the blueprint explicitly calls for that ratio.
- **Images in galleries and grids must be square or near-square.** Rectangular thumbnails with cramped content look low-quality and break visual rhythm. Use `.aspectRatio(1)` on gallery tile containers, and prefer `ImageFit.Cover` with overflow clipping. Block galleries where rows contain mismatched aspect ratios.
- **Buttons in the bottom bar/bottom nav area must be compact.** A primary CTA at the bottom of the screen should use a 44-52px height range. Buttons taller than 56px or with excessive vertical padding that create a large empty block below content are a blocking `button-too-tall` finding.
- **Spacing must feel intentional, not accidental.** Elements must not stick to each other unless they form a logical group. Each section must have a clear visual boundary: section spacing >= 20px, card/internal spacing = 12-16px, inline spacing = 8px. Use a spacing scale (8/12/16/24/32) across all screens. Random spacing values scattered across screens are a `spacing-inconsistency` finding.
- **Screen content must fill the viewport naturally.** A screen with large blank areas at the bottom (empty space exceeding 15% of screen height) is a `dead-space` finding. Content that requires excessive vertical scrolling to reach one more item is acceptable only when the list is long. A screen with fewer than 4 content rows should fit without scrolling.
- **Pill/capsule controls must have proportional padding.** Chips with padding wider than 2x their text width look bloated. Use `padding(horizontal: 12, vertical: 6)` for chip labels, not wide block padding.
- **Cards and containers must share one visual rhythm.** All cards on the same screen or across same-role screens must use the same border-radius and padding. Mixed radii (some 12, some 20, some 24) are a `geometry-inconsistency` finding.
- **Typography must follow a scale.** Use at most 4 font sizes per screen: title (24-28px bold), section (16px bold), body (14-15px), label (10-13px). Font sizes outside the expected bands are a `typography-drift` finding.

## Screenshot Analysis for Sleekness

### Priority Rule: Gut Over Checklist

The reviewer is an independent thinker first and a dimension-checker second. When gut instinct and checklist disagree, gut wins. This is explicit:

- **Gut instinct is the override.** If every dimension scores PASS but the reviewer still feels "I wouldn't use this," "this looks off," or "something bothers me" — the verdict is FAIL. The reviewer must describe what bothers them. That description becomes the gap inventory.
- **"It doesn't feel good" is a sufficient reason to fail.** The dimensions exist to structure the review, not to constrain it. Use them to organize observations, but never let a clean dimension score silence an honest negative reaction.
- **The review question is: would a human accept this?** Not "does it pass the dimensions?" The dimensions are tools for articulating WHY a human would or wouldn't accept it, not the acceptance criteria themselves.

### Human visual review

Review screenshots or live UI evidence for alignment, containment, spacing, typography, contrast, touch targets, state feedback, responsive behavior, and honesty of displayed data. Identify concrete screen locations and prioritize the few changes with the greatest user impact.

Use an available image-analysis tool when helpful, but it is optional. Native visual inspection or user-provided screenshots are valid evidence. Do not invent a tool result, require a fixed prompt, demand a minimum number of findings, or fail an otherwise acceptable maintenance change solely on subjective enthusiasm. Apply a release-polish bar only when the user asks for presentation-ready UI.

### Expanded Dimension Checks

For deeply flawed screens where the 8-dimension review returns 15+ findings, or for borderline screens needing pixel-level scrutiny before a ship decision, load `references/screenshot-review-checklist.md` for expanded sub-checks per dimension. Do not load it by default — use it only when the base 8-dimension review produces ambiguous results.

### Post-Review Requirements

- **Record the full AI reviewer response verbatim.**
- **Ship-verdict gate**: If Part A of dimension 8 is any form of NO, the verification is a FAILURE. The implementor must fix every numbered finding from Part B, re-screenshot, and re-review until Part A says YES.
- **Perceived-quality gate (dimension 6)**: Score <6/10 = FAIL, redesign required. Score <8/10 = fix required until ≥8.
- **Visual-interest gate (dimension 3)**: Score <5/10 = FAIL.
- **Complete fix mandate**: Implementor MUST fix every single numbered finding in Part B. Provide a fix log: finding # → action taken → new screenshot evidence.
- **This review runs on BOTH the primary screen and EVERY secondary screen.** Each distinct screen layout gets its own 8-dimension review with its own gap inventory.

## Responsive and Multi-Device Scaling
- **Values must not be hard-coded for a single resolution.** Use percentage widths (`'100%'`, `'48%'`), `layoutWeight`, and `aspectRatio` instead of fixed-pixel widths. Fixed widths like `.width(320)` or `.height(600)` on the root container are blocking `hardcoded-resolution` findings.
- **Gallery grids must use percentage column widths.** Use `'30%'` or `'48%'` for gallery/tile columns, not fixed pixel values. This ensures the grid scales from phone to tablet.
- **Spacing must not break on wider screens.** Use the same spacing scale on tablet as on phone. Do not add extra-large padding only on tablet — the content should naturally fill more columns, not stretch with double spacing.
- **Tablet verification:** When the previewer supports a tablet-sized resolution, verify that cards resize gracefully, text remains readable, grids add columns naturally, and no element clips or overflows. On tablet, a 3-column phone grid may become a 5-column grid.

## Mobile Shell And Navigation
- Treat the app shell as a product object: status area, header, content, bottom navigation, and home indicator should look intentionally composed.
- Bottom navigation must never cover the last content row. If content is long, shorten previews, use a scroll/list pattern, or reserve a real bottom inset.
- Bottom navigation must also not float above a large empty footer. The correct pattern is header with fixed height, content using remaining space, tabbar near the bottom, then a small home indicator/safe area.
- Avoid percentage-only height guesses for app shells. Prefer a fixed-size bottom bar plus `layoutWeight(1)` or equivalent for the main content region.
- Check every main scenario, not only the first screen: Home/list, Calendar/schedule, Overview/chart, Profile/settings, editor/sheet, empty states, and any modal/bottom sheet.
- Icons and labels should be centered inside fixed-size containers. Use `Stack` or balanced Row/Column composition for glyph controls; padding-only centering often looks off on real devices.
- Header search/add buttons, close controls, active tabs, icon glyphs, and labels must be visibly centered inside their hit areas.
- Leave only a small intentional safe-area/home-indicator gap under the tabbar; a large blank footer is a blocker.
- If the user points to a screenshot reference, compare bottom spacing, active tab shape, icon alignment, content density, and first/last visible rows against that reference before editing color or copy.

## Touch And Interaction
- Touch controls should aim for 44pt hit areas when feasible.
- Controls must never overlap, clip, or require precision taps near screen edges.
- Every visible control should produce visible mock feedback: selected, liked, saved, followed, disabled, toast, sheet, navigation, or empty state.
- Treat a visible but inert control as a bug. If a single-file demo cannot perform real work, it still needs mock state feedback.
- Do not accept grouped coverage for primary controls. If five settings rows, seven checklist rows, or four chart tabs are visible, each one needs its own scenario row or an explicit `manual-required` reason.
- Do not accept grouped coverage for wizard/configuration controls. `Availability rows`, `preferences`, or `settings` is not a scenario; `Weekdays`, `Wednesday`, `Sunday`, `Office gym`, `Home gym`, `Weekly treat`, and `Dog walk` each need separate evidence when visible.
- A toast alone is not enough for settings, input, chart, or generated-plan controls unless the user story says the entire action is informational.
- Swipes, taps, sheets, tabs, and navigation should follow the product's expected mental model.
- Disabled/demo-only actions must say what happened instead of silently doing nothing.
- Before claiming interaction coverage, write a scenario test plan from the actual app surface. Use `scripts/arkts_ui_validation_matrix_check.py` only when it is available; otherwise check coverage manually. Each row should include `scenario_id`, `requirement_id`, `source_control_id`, `start_state`, `actions`, `expected_feedback`, `actual_visible_change`, available evidence, and final status.

## Previewer-Safe ArkUI Patterns
- Avoid `Text.fontColor(...)` in the current dynamic previewer path if it is known to break the build.
- Avoid network images for device demos unless permissions, loading state, and visual fallback are explicitly verified.
- Prefer compact styled `Text` controls over `Button` when default button minimum sizing causes overlap or a system-form look.
- Use direct clickable controls for critical interactions; container-level clicks can be harder to smoke through the canvas bridge.
- Keep single-file dynamic demos conservative with helper builders if previous attempts caused memo/context compiler errors.

## State Coverage
Verify visible states for the relevant app surface:
- loading or skeleton
- empty result
- liked and unliked
- saved and unsaved
- followed and unfollowed
- disabled/demo action
- error or unavailable fallback

Every editable value must update the current screen and every promised downstream surface. The validation report must prove both layers with screenshots: the control changed locally, then the generated plan, overview, calendar, settings summary, data screen, or progress chart changed where promised. Charts, progress graphs, totals, summaries, and calendars must be state-derived or clearly labeled as fixed sample estimates. If edited data does not propagate, classify the issue as `non-propagating-state`, `downstream-not-tested`, `stale-chart`, `fake-data`, or `date-not-real`.

For personalized planners, availability/preferences/settings are product inputs, not decorative toggles. They must change visible planning outputs. If a toggle only changes its own row or a toast, the app is incomplete until at least one downstream planning surface changes or the control is restyled as local-only.

## Review Heuristics
- Match between app and user expectations: does the UI behave like the requested product category?
- Visibility of system status: does every tap/swipe show feedback?
- Consistency: do feed, sheets, profile, search, create, and inbox feel like the same product?
- Error prevention and recovery: are fallbacks and disabled actions understandable?
- Recognition over recall: are controls self-evident from placement, icon, and state?
