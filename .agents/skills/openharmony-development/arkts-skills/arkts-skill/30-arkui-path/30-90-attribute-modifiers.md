# Attribute modifiers (AttributeModifier, RowAttribute, ImageAttribute, CheckboxAttribute)

Status: placeholder.

`AttributeModifier`, `RowAttribute`, `ImageAttribute`, and `CheckboxAttribute` are imported in ComponentSample (`CommonText.ets`) but no class in the sample implements `AttributeModifier` or calls `applyNormalAttribute`. No current static sample grounds these APIs.

## What is still missing
- `AttributeModifier` interface with `applyNormalAttribute(instance)`
- `RowAttribute`, `ImageAttribute`, `CheckboxAttribute`, `ButtonAttribute`, `TextAttribute` dynamic styling
- class-based attribute application vs inline method chains
- distinct failure signatures (attribute not applied, wrong target type, modifier lifecycle)

Do not generate these APIs from general UI styling habit. Wait for a grounded static sample.
