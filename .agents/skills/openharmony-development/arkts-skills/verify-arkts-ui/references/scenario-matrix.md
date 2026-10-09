# Scenario Matrix Verification

Use this reference for full verification and iterative repair. It turns app promises and source-visible controls into evidence-backed scenarios.

## Contracts
Build these contracts before UI verification:

### User Story Contract
Record promised screens, editable inputs, stateful values, downstream summaries/charts, user-visible success criteria, and selected design-system manifest inputs when available.

If a design-system id is provided, load its `manifest.json`, `DESIGN.md`, and `USAGE.md`. Treat manifest `requiredScreens`, `requiredStates`, `primaryControls`, and `qualityGates` as verification inputs.

### State Propagation Contract
For every editable input, toggle, chip, setting row, metric control, chart tab, and generated-plan input, record:
- visible control label and expected `source_control_id`
- state fields touched
- current-screen feedback that must change immediately
- downstream surfaces that must change later, such as generated plan, overview, calendar schedule, settings summary, data screen, or progress chart
- whether the control is stateful, informational-only, fixed demo estimate, or intentionally non-tappable

A control cannot be called functional from a click alone. It must prove local feedback and promised downstream propagation.

### Date Source Contract
For calendar, planner, habit, health, schedule, or timeline apps, record the runtime date provider, surfaces that consume it, and expected displayed today/month/week values. Stale literal dates fail unless clearly labeled as fixed samples.

### Styling Consistency Contract
Record intended visual-system tokens and component geometry: colors, content width, screen padding, card radius, row radius, CTA height, CTA radius, row height, chip height, nav height, icon container size, and typography scale. Primary screens must reuse tokens unless a decorative exception is named.

## Source and style inventories

Inventory source-visible controls, state bindings, navigation modes, charts, summaries, date sources, and style tokens. When the optional helper scripts are present, they may produce a machine-readable starting point:

```bash
python3 scripts/arkts_ui_scenario_inventory.py --json <target.ets>
```

When the script is absent, inspect the relevant `.ets` source directly and record the same fields manually. A missing helper is not a verification failure.

Treat controls with `control_state_binding_status: "unknown"` or `"toast-only"` as blockers for primary controls unless the scenario matrix marks them non-stateful or `manual-required` with a concrete reason.

Optional style inventory:

```bash
python3 scripts/arkts_ui_style_inventory.py --json <target.ets>
```

Whether automated or manual, record the declared style token set and inspect mixed content widths, excessive geometry literals, CTA/nav drift, and unexplained outliers. Treat demonstrated requirement or accessibility failures as blocking; ordinary visual polish depends on the user's requested quality bar.

## Scenario matrix requirements
Merge the contracts and inventories into an exhaustive scenario matrix. A full verification report is invalid if any source control, visible setting, editable input, navigation mode, chart, downstream surface, date surface, style quality gate, or promised user-story requirement is absent without an explicit `manual-required` reason.

Do not use grouped or representative coverage for primary controls. Each visible stateful control discovered from source must have its own scenario row.

Use this row shape:

```text
scenario_id, requirement_id, source_control_id, screen, control_label, start_state, actions, state_touched, downstream_surfaces, expected_feedback, expected_visible_change, actual_visible_change, result_reason, evidence_before, evidence_after, evidence_current_screen_after, evidence_downstream_after, status
```

For single-file ArkUI demos, the minimum plan covers:
- app launch and title
- all bottom tabs
- every visible sheet or modal
- create/save/cancel/delete flows when present
- toggles, chips, and selected states
- every visible settings, measurement, or unit row
- date-source surfaces
- charts and summaries
- styling consistency evidence for all main screens
- primary row/card actions

## Matrix validation

Validate coverage before accepting a full interaction report. Use the optional checker when available:

```bash
python3 scripts/arkts_ui_validation_matrix_check.py --inventory <inventory.json> --report <report.json|md>
```

When the checker is absent, apply the same coverage rules manually. Passed rows must name the observed visible change and available evidence.

A reported checker failure or an equivalent manual coverage gap prevents a full-verification claim. It does not erase narrower build or render evidence that genuinely passed.

## Click-through evidence rules
- Save before/after screenshots for key scenario states.
- A scenario is `passed` only when the after screenshot shows the expected visible state, navigation, value, selected state, or label change.
- Stable screenshots after a tap are `failed-open` unless the expected result is explicitly no mutation.
- Toast-only behavior fails unless the user story says the whole behavior is a toast.
- Settings rows with chevrons must navigate to real editors. Toggle-like settings must show inline selected state.
- Critical CTA and navigation controls implemented through helper builders with callback parameters are high-risk until click-through evidence proves they fire.
- Calendar, planner, habit, and health apps must prove date-keyed state, not a single global bucket.
- Fake charts, dates, totals, and summaries fail unless explicitly labeled fixed sample estimates.
- If the canvas bridge cannot reliably exercise a scenario, mark it `manual-required`; do not silently skip it.

## Failure classes
Use these classes for failed or repaired scenarios:

- `missing-control`
- `missing-state-binding`
- `builder-state-opaque`
- `dead-control`
- `toast-only-control`
- `fake-data`
- `non-propagating-state`
- `shared-date-state`
- `downstream-not-tested`
- `grouped-coverage-invalid`
- `stale-chart`
- `date-source-missing`
- `date-not-real`
- `stale-runtime-date`
- `calendar-not-useful`
- `setting-row-dead`
- `setting-row-toast-only`
- `setting-row-no-local-change`
- `handler-no-visible-effect`
- `coordinate-uncertain`
- `visual-regression`
- `inconsistent-style-token`
- `inconsistent-component-geometry`
- `inconsistent-cta`
- `inconsistent-nav`
- `visual-system-drift`

## Confidence labels
Report the current environment as one of:
- `app-render-smoke`
- `manual-required`
- `component-test-tooling-ready`

Report interaction confidence as one of:
- `screenshot-only`
- `coordinate-smoke`
- `manual-confirmed`
- `component-test-tooling-ready`

If serious automated click/swipe tests are required, convert to a normal ArkUI project and use native ArkUI component tests with `Tester`/`Matcher`.
