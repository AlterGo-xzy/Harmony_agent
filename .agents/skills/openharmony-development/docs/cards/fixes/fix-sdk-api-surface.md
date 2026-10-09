---
guide_id: fixes/fix-sdk-api-surface
family: fixes
tags: fix, sdk, api, deprecated, whitelist, behavior change, disabled, num2int, syscap
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:BuiltinDisableApi, linter-fault:BuiltinNewCtor, linter-fault:BuiltinNoCtorFunc, linter-fault:DeprecatedProcessApi, linter-fault:DuplicateDeclNameFromSdk, linter-fault:ForbiddenSdkApiKeyword, linter-fault:IsConcurrentDeprecated, linter-fault:LimitedStdLibApi, linter-fault:NoDeprecatedApi, linter-fault:QuotedHyphenPropsDeprecated, linter-fault:SdkAbilityAsynchronousLifecycle, linter-fault:SdkCommonApiBehaviorChange, linter-fault:SdkCommonApiDeprecated, linter-fault:SdkCommonApiWhiteList, linter-fault:SetCloneListDeprecated, linter-fault:SetTransferListDeprecated, linter-fault:SharedArrayBufferDeprecated, linter-fault:UseConcurrentDeprecated, linter-fault:UseSharedDeprecated
related_migration_patterns: any-or-unknown
status: active
---
# Fix SDK API Surface Usage Errors

## Intent

Fix SDK API usage errors by using approved API surfaces and avoiding deprecated, disabled, or behavior-changed SDK features.

## Use When

- code calls a deprecated or removed SDK API
- code uses a forbidden SDK keyword or internal symbol
- code relies on SDK overload behavior that has changed
- code passes a floating-point value where the SDK expects an integer

## Do

- check each SDK import against the current deprecation and syscap status before use
- replace forbidden SDK keywords with their approved equivalents
- update call sites to match current SDK overload names
- apply num2int conversion rules when an SDK method expects an integer parameter

## Avoid

- calling deprecated SDK methods without checking for a replacement
- using internal or unlisted SDK symbols that bypass the public API surface
- assuming SDK overload signatures are unchanged from prior versions
- passing fractional numbers to SDK parameters that expect integers

## Migration Notes

SDK surface changes accumulate across HarmonyOS versions. Verify the target API level and syscap set before relying on any SDK feature.


## Related Diagnostics

- `linter-fault:BuiltinDisableApi`
- `linter-fault:BuiltinNewCtor`
- `linter-fault:BuiltinNoCtorFunc`
- `linter-fault:DeprecatedProcessApi`
- `linter-fault:DuplicateDeclNameFromSdk`
- `linter-fault:ForbiddenSdkApiKeyword`
- `linter-fault:IsConcurrentDeprecated`
- `linter-fault:LimitedStdLibApi`
- `linter-fault:NoDeprecatedApi`
- `linter-fault:QuotedHyphenPropsDeprecated`
- `linter-fault:SdkAbilityAsynchronousLifecycle`
- `linter-fault:SdkCommonApiBehaviorChange`
- `linter-fault:SdkCommonApiDeprecated`
- `linter-fault:SdkCommonApiWhiteList`
- `linter-fault:SetCloneListDeprecated`
- `linter-fault:SetTransferListDeprecated`
- `linter-fault:SharedArrayBufferDeprecated`
- `linter-fault:UseConcurrentDeprecated`
- `linter-fault:UseSharedDeprecated`

## Status
Active. Use this card when fixing SDK API surface diagnostic errors during ArkTS migration.
