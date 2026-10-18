# M11-E review

ArtifactPolicyReleaseRunner now bounds every baseline, shadow, canary, and active policy attempt. Each attempt receives a cooperative cancellation signal; timeout and external cancellation settle once and ignore late Promise results.

Fallback behavior is explicit: shadow timeout is observational, canary timeout falls back to active, active timeout falls back to the validated baseline, and baseline timeout or external cancellation fails closed.

The change adds no task creation or control API. AgentRuntimeFacade remains the sole task-control entry. This batch did not build a HAP, sign, install, run a device, call a Provider, or use credentials.
