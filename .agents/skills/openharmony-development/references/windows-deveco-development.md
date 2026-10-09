# Windows DevEco development

Use this reference for OpenHarmony/HarmonyOS projects built on Windows with DevEco Studio and Hvigor. Project files and live tool output override every example below.

## Detect the project

Identify the project root from `build-profile.json5`, `hvigorfile.ts`, `oh-package.json5`, and the module directories. Read the root profile and every touched module's `build-profile.json5`, `module.json5`, `oh-package.json5`, and `hvigorfile.ts` before choosing a task.

Determine whether the target module is a HAP, HAR, HSP, or another artifact from its Hvigor plugin and project profile. Do not infer the task from the directory name.

## Select the launcher

Use this order:

1. a checked-in `hvigorw.bat` or documented project command;
2. the installed DevEco Studio launcher after verifying its path;
3. an available ArkTS Agent Kit wrapper when the project explicitly uses it.

Discover the installed DevEco SDK and Hvigor launcher on the active machine, then verify both paths before use. Set `DEVECO_SDK_HOME` only for the build process; do not make an unrequested persistent environment change.

## Construct the build command from project evidence

Read module names, products, targets, artifact types, and SDK requirements from the target project's profiles. Use those discovered values to construct the narrowest applicable build command. For example:

```powershell
$env:DEVECO_SDK_HOME='<verified-sdk-path>'
& '<verified-hvigorw-path>' --mode module -p module=<module>@<target> -p product=<product> <assemble-task> --no-daemon
```

The placeholders must be replaced only with values verified from the active project and development environment. The example is not permission to build every task; use the narrowest target relevant to the user's request.

## Build and diagnostic loop

1. Record the project root, module, product, target, artifact type, and expected output.
2. Run the narrowest native task available.
3. Read the first actionable diagnostic and its source location before editing.
4. Make one coherent fix, then rerun the same task.
5. Escalate to a wider build only when the narrow build cannot validate the affected boundary.

Do not run `ohpm install`, download SDK components, change signing configuration, or alter global DevEco settings merely to make a build proceed. Request authorization when external downloads or persistent configuration changes are required.

## Verification boundaries

- A successful HAR build verifies library compilation, not HAP launch behavior.
- A successful HAP build verifies artifact production, not signing, installation, launch, UI rendering, or device behavior.
- Device tests require an available authorized device and actual runtime evidence.
- Previewer output is not equivalent to real-device capability evidence.

## Cleanup safety

Prefer the project's native clean task. Before deleting build caches, resolve the exact absolute project root and list the target directories. Do not use recursive deletion against unresolved relative paths, wildcards, the workspace root, or a user profile. Preserve unrelated outputs and report what was removed.
