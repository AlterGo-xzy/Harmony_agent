# ArkTS Performance Notes

This repo treats performance as a bounded improvement workflow, not as generic “cleanup”.

## Priorities

- keep numeric intent explicit when arithmetic or indexing behavior matters
- use compiler warnings as hints about inefficient or non-canonical code shape
- avoid dynamic or weakly typed patterns that hide allocation or control-flow costs
- review behavior-sensitive optimizations separately from style modernization

## Workflow

1. Start from a concrete hotspot, warning family, or user goal.
2. Read the related optimization cards first.
3. Preserve semantics while reducing the targeted cost.
4. Re-run `arkts-check`.
5. Use `review-arkts` when the optimization touches public contracts or subtle semantics.
