# Blueprint Format

Use this shape before implementation:

```markdown
## App Blueprint
- goal:
- selected_category:
- selected_design_system:
- category_confidence:
- selected_archetype:
- fallback_rationale:
- personalization_assumptions:
- constraints:
- density_unit_plan:
- design_system_quality_gates:

## Screens
- screen_id | purpose | main controls | states

## State And Mock Data
- state fields:
- mock records:
- computed values:
- fixed demo estimates:

## State Propagation Contract
- control | state | current_screen_feedback | downstream_surfaces | chart_or_summary_binding

## Controls And Feedback
- control | action | expected visible feedback

## Scenario Test Plan
- scenario_id | requirement_id | source_control_hint | start_state | actions | expected_feedback | expected_current_screen_change | expected_downstream_change | evidence

## Verification
- arkts-check/build command:
- device workflow command:
- previewer fallback command, if `arkui-device-cli check-device` does not find a device:
- required screenshots:
- residual risks:
```

Keep the blueprint compact. Do not include implementation code here; reserve code for `implement-arkts`.

The `design_system_quality_gates` field should be copied or summarized from the selected design-system manifest. It is the checklist that the verification workflow in root `VERIFICATION.md` must later audit against using the available previewer, device, or user-provided evidence.
