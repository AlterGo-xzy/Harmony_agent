import { ArtifactKind, ArtifactLifecycleStatus } from '@harmony_agent/agent-contracts';
import { ArtifactRegistryEntry } from './ArtifactRegistryTypes';
import {
  ARTIFACT_POLICY_RELEASE_VERSION,
  ArtifactBaselinePolicyPort,
  ArtifactCanaryAssignmentPort,
  ArtifactCanaryBucketPort,
  ArtifactPolicyDecision,
  ArtifactPolicyExecutionMode,
  ArtifactPolicyFallbackCode,
  ArtifactPolicyReleaseConfig,
  ArtifactPolicyRequest,
  ArtifactPolicyRunCode,
  ArtifactPolicyRunResult,
  ArtifactReleaseRegistryViewPort,
  ArtifactReleasedPolicyPort,
  ArtifactShadowObservation,
  ArtifactShadowObservationCode,
  copyArtifactForRelease,
  copyArtifactPolicyDecision,
  copyArtifactPolicyRequest
} from './ArtifactPolicyReleaseTypes';

function validText(value: string): boolean {
  return value.trim().length > 0;
}

function validKind(value: ArtifactKind): boolean {
  return value === ArtifactKind.CHECKPOINT || value === ArtifactKind.POLICY || value === ArtifactKind.WORKFLOW;
}

function validJsonObject(value: string, requireNonEmpty: boolean): boolean {
  if (!validText(value)) return false;
  let parsed: Object;
  try {
    parsed = JSON.parse(value) as Object;
  } catch (error) {
    return false;
  }
  if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) return false;
  return !requireNonEmpty || Object.keys(parsed).length > 0;
}

function validRequest(value: ArtifactPolicyRequest): boolean {
  if (value.version !== ARTIFACT_POLICY_RELEASE_VERSION || !validText(value.requestId) ||
    !validKind(value.artifactKind) || value.candidateIds.length === 0 ||
    !validJsonObject(value.inputJson, false)) return false;
  for (let i: number = 0; i < value.candidateIds.length; i++) {
    if (!validText(value.candidateIds[i])) return false;
    for (let j: number = 0; j < i; j++) {
      if (value.candidateIds[i] === value.candidateIds[j]) return false;
    }
  }
  return true;
}

function includes(values: string[], expected: string): boolean {
  for (let i: number = 0; i < values.length; i++) if (values[i] === expected) return true;
  return false;
}

function validDecision(value: ArtifactPolicyDecision, candidates: string[]): boolean {
  return validText(value.selectedId) && includes(candidates, value.selectedId) &&
    validJsonObject(value.evidenceJson, true);
}

function validRegistryEntry(value: ArtifactRegistryEntry, kind: ArtifactKind,
  expectedStatus: ArtifactLifecycleStatus): boolean {
  return validText(value.manifest.artifactId) && value.manifest.artifactKind === kind &&
    value.manifest.lifecycleStatus === expectedStatus &&
    /^sha256:[0-9a-f]{64}$/.test(value.manifest.artifactDigest) &&
    /^sha256:[0-9a-f]{64}$/.test(value.packageDigest);
}

class CandidateAttempt {
  accepted: boolean = false;
  failed: boolean = false;
  decision?: ArtifactPolicyDecision;
}

export class DeterministicArtifactCanaryAssignment implements ArtifactCanaryAssignmentPort {
  private readonly bucketPort: ArtifactCanaryBucketPort;

  constructor(bucketPort: ArtifactCanaryBucketPort) {
    this.bucketPort = bucketPort;
  }

  assigned(requestId: string, artifactDigest: string, trafficBasisPoints: number): boolean {
    if (!validText(requestId) || !/^sha256:[0-9a-f]{64}$/.test(artifactDigest) ||
      !Number.isSafeInteger(trafficBasisPoints) || trafficBasisPoints < 0 || trafficBasisPoints > 10000) {
      throw new Error('canary assignment input is invalid');
    }
    if (trafficBasisPoints === 0) return false;
    if (trafficBasisPoints === 10000) return true;
    const bucket: number = this.bucketPort.bucket(requestId, artifactDigest);
    if (!Number.isSafeInteger(bucket) || bucket < 0 || bucket >= 10000) {
      throw new Error('canary bucket must be between 0 and 9999');
    }
    return bucket < trafficBasisPoints;
  }
}

export class ArtifactPolicyReleaseRunner {
  private readonly registry: ArtifactReleaseRegistryViewPort;
  private readonly baseline: ArtifactBaselinePolicyPort;
  private readonly released: ArtifactReleasedPolicyPort;
  private readonly assignment: ArtifactCanaryAssignmentPort;
  private readonly config: ArtifactPolicyReleaseConfig;

  constructor(registry: ArtifactReleaseRegistryViewPort, baseline: ArtifactBaselinePolicyPort,
    released: ArtifactReleasedPolicyPort, assignment: ArtifactCanaryAssignmentPort,
    config: ArtifactPolicyReleaseConfig) {
    if (!Number.isSafeInteger(config.canaryTrafficBasisPoints) || config.canaryTrafficBasisPoints < 0 ||
      config.canaryTrafficBasisPoints > 10000 || !Number.isSafeInteger(config.maxShadowEvaluations) ||
      config.maxShadowEvaluations < 0) {
      throw new Error('artifact release config is invalid');
    }
    this.registry = registry;
    this.baseline = baseline;
    this.released = released;
    this.assignment = assignment;
    this.config = new ArtifactPolicyReleaseConfig();
    this.config.canaryTrafficBasisPoints = config.canaryTrafficBasisPoints;
    this.config.maxShadowEvaluations = config.maxShadowEvaluations;
  }

  async run(request: ArtifactPolicyRequest): Promise<ArtifactPolicyRunResult> {
    const result: ArtifactPolicyRunResult = new ArtifactPolicyRunResult();
    if (!validRequest(request)) return result;
    let baselineDecision: ArtifactPolicyDecision;
    try {
      baselineDecision = await this.baseline.decide(copyArtifactPolicyRequest(request));
    } catch (error) {
      result.code = ArtifactPolicyRunCode.BASELINE_FAILED;
      return result;
    }
    if (!validDecision(baselineDecision, request.candidateIds)) {
      result.code = ArtifactPolicyRunCode.BASELINE_FAILED;
      return result;
    }
    result.baselineDecision = copyArtifactPolicyDecision(baselineDecision);

    let shadows: ArtifactRegistryEntry[];
    let canary: ArtifactRegistryEntry | undefined;
    let active: ArtifactRegistryEntry | undefined;
    try {
      shadows = this.registry.shadowArtifacts(request.artifactKind);
      canary = this.registry.canaryArtifact(request.artifactKind);
      active = this.registry.activeArtifact(request.artifactKind);
    } catch (error) {
      return this.useBaseline(result, baselineDecision, ArtifactPolicyFallbackCode.REGISTRY_FAILED);
    }
    await this.observeShadows(result, shadows, request);

    let canaryFallback: ArtifactPolicyFallbackCode = ArtifactPolicyFallbackCode.NONE;
    if (canary !== undefined) {
      if (!validRegistryEntry(canary, request.artifactKind, ArtifactLifecycleStatus.CANARY)) {
        canaryFallback = ArtifactPolicyFallbackCode.CANARY_REJECTED;
      }
      let assigned: boolean = false;
      if (canaryFallback === ArtifactPolicyFallbackCode.NONE && this.config.canaryTrafficBasisPoints > 0) {
        try {
          assigned = this.assignment.assigned(
            request.requestId, canary.manifest.artifactDigest, this.config.canaryTrafficBasisPoints);
        } catch (error) {
          canaryFallback = ArtifactPolicyFallbackCode.CANARY_ASSIGNMENT_FAILED;
        }
      }
      if (canaryFallback === ArtifactPolicyFallbackCode.NONE && assigned) {
        const attempt: CandidateAttempt = await this.attempt(canary, request);
        if (attempt.accepted && attempt.decision !== undefined) {
          return this.useReleased(result, attempt.decision, canary.manifest.artifactDigest,
            ArtifactPolicyExecutionMode.CANARY, ArtifactPolicyFallbackCode.NONE);
        }
        canaryFallback = attempt.failed ? ArtifactPolicyFallbackCode.CANARY_FAILED :
          ArtifactPolicyFallbackCode.CANARY_REJECTED;
      } else if (canaryFallback === ArtifactPolicyFallbackCode.NONE) {
        canaryFallback = ArtifactPolicyFallbackCode.CANARY_NOT_ASSIGNED;
      }
    }

    if (active !== undefined) {
      if (!validRegistryEntry(active, request.artifactKind, ArtifactLifecycleStatus.ACTIVE)) {
        return this.useBaseline(result, baselineDecision, ArtifactPolicyFallbackCode.ACTIVE_REJECTED);
      }
      const attempt: CandidateAttempt = await this.attempt(active, request);
      if (attempt.accepted && attempt.decision !== undefined) {
        return this.useReleased(result, attempt.decision, active.manifest.artifactDigest,
          ArtifactPolicyExecutionMode.ACTIVE, canaryFallback);
      }
      return this.useBaseline(result, baselineDecision,
        attempt.failed ? ArtifactPolicyFallbackCode.ACTIVE_FAILED : ArtifactPolicyFallbackCode.ACTIVE_REJECTED);
    }
    return this.useBaseline(result, baselineDecision,
      canaryFallback === ArtifactPolicyFallbackCode.NONE ? ArtifactPolicyFallbackCode.NO_RELEASE : canaryFallback);
  }

  private async observeShadows(result: ArtifactPolicyRunResult, shadows: ArtifactRegistryEntry[],
    request: ArtifactPolicyRequest): Promise<void> {
    const count: number = Math.min(shadows.length, this.config.maxShadowEvaluations);
    for (let i: number = 0; i < count; i++) {
      const observation: ArtifactShadowObservation = new ArtifactShadowObservation();
      observation.artifactId = shadows[i].manifest.artifactId;
      observation.artifactDigest = shadows[i].manifest.artifactDigest;
      if (!validRegistryEntry(shadows[i], request.artifactKind, ArtifactLifecycleStatus.SHADOW)) {
        observation.code = ArtifactShadowObservationCode.REJECTED;
        result.shadowObservations.push(observation);
        continue;
      }
      const attempt: CandidateAttempt = await this.attempt(shadows[i], request);
      if (attempt.accepted && attempt.decision !== undefined) {
        observation.code = ArtifactShadowObservationCode.ACCEPTED;
        observation.selectedId = attempt.decision.selectedId;
      } else {
        observation.code = attempt.failed ? ArtifactShadowObservationCode.FAILED :
          ArtifactShadowObservationCode.REJECTED;
      }
      result.shadowObservations.push(observation);
    }
  }

  private async attempt(artifact: ArtifactRegistryEntry, request: ArtifactPolicyRequest): Promise<CandidateAttempt> {
    const result: CandidateAttempt = new CandidateAttempt();
    let decision: ArtifactPolicyDecision;
    try {
      decision = await this.released.decide(
        copyArtifactForRelease(artifact), copyArtifactPolicyRequest(request));
    } catch (error) {
      result.failed = true;
      return result;
    }
    if (!validDecision(decision, request.candidateIds)) return result;
    result.accepted = true;
    result.decision = copyArtifactPolicyDecision(decision);
    return result;
  }

  private useReleased(result: ArtifactPolicyRunResult, decision: ArtifactPolicyDecision,
    artifactDigest: string, mode: ArtifactPolicyExecutionMode,
    fallback: ArtifactPolicyFallbackCode): ArtifactPolicyRunResult {
    result.accepted = true;
    result.code = ArtifactPolicyRunCode.SUCCESS;
    result.executionMode = mode;
    result.fallbackCode = fallback;
    result.selectedArtifactDigest = artifactDigest;
    result.decision = copyArtifactPolicyDecision(decision);
    return result;
  }

  private useBaseline(result: ArtifactPolicyRunResult, baseline: ArtifactPolicyDecision,
    fallback: ArtifactPolicyFallbackCode): ArtifactPolicyRunResult {
    result.accepted = true;
    result.code = ArtifactPolicyRunCode.SUCCESS;
    result.executionMode = ArtifactPolicyExecutionMode.BASELINE;
    result.fallbackCode = fallback;
    result.selectedArtifactDigest = '';
    result.decision = copyArtifactPolicyDecision(baseline);
    return result;
  }
}
