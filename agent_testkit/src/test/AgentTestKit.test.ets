import { describe, expect, it } from '@ohos/hypium';
import {
  AGENT_TESTKIT_SCHEMA_VERSION,
  AGENT_TESTKIT_VERSION,
  BenchmarkArm,
  BenchmarkArmKind,
  BenchmarkEvaluator,
  BenchmarkManifest,
  BenchmarkManifestValidator,
  BenchmarkRecordResult,
  BenchmarkSample,
  BenchmarkSummary,
  DeterministicFaultInjector,
  FaultKind,
  FaultPhase,
  FaultRule,
  FaultScript,
  FaultScriptValidator,
  IntegrationFixtureCatalog,
  IntegrationFixtureDescriptor,
  IntegrationFixtureKind
} from '../../Index';

function arm(armId: string, kind: BenchmarkArmKind): BenchmarkArm {
  const value: BenchmarkArm = new BenchmarkArm();
  value.armId = armId;
  value.kind = kind;
  value.permissionPolicyVersion = 'permission-policy-7';
  value.contextPolicyVersion = 'context-policy-4';
  return value;
}

function manifest(): BenchmarkManifest {
  const value: BenchmarkManifest = new BenchmarkManifest();
  value.benchmarkId = 'harmony-agent-bench-pilot';
  value.suiteVersion = '2026.10.12';
  value.frozenAt = '2026-10-12T00:00:00+08:00';
  value.datasetDigest = 'sha256:dataset-pilot-v1';
  value.modelId = 'fixture-model-balanced';
  value.modelVersion = '2026-09';
  value.providerId = 'fixture-provider';
  value.region = 'local-fixture';
  value.priceSnapshotId = 'fixture-price-2026-10-12';
  value.priceSnapshotDigest = 'sha256:fixture-price-v1';
  value.routerPolicyVersion = 'deterministic-router-1';
  value.arms = [
    arm('strong-single', BenchmarkArmKind.STRONG_SINGLE_AGENT),
    arm('multi-agent', BenchmarkArmKind.MULTI_AGENT)
  ];
  return value;
}

function sample(caseId: string, runId: string, armId: string, latencyMs: number): BenchmarkSample {
  const value: BenchmarkSample = new BenchmarkSample();
  value.caseId = caseId;
  value.runId = runId;
  value.armId = armId;
  value.passed = true;
  value.qualityScoreBasisPoints = 8200;
  value.inputTokens = 1100;
  value.outputTokens = 240;
  value.monetaryCostMicros = 3200;
  value.latencyMs = latencyMs;
  value.toolCalls = 2;
  value.agentActivations = armId === 'multi-agent' ? 2 : 1;
  value.recoveryEvents = 0;
  value.routerDecisions = 2;
  value.routerCorrectDecisions = 2;
  return value;
}

function rule(ruleId: string, occurrence: number, kind: FaultKind): FaultRule {
  const value: FaultRule = new FaultRule();
  value.ruleId = ruleId;
  value.targetId = 'provider:model.generate';
  value.phase = FaultPhase.DURING_CALL;
  value.occurrence = occurrence;
  value.kind = kind;
  return value;
}

export default function agentTestKitTest(): void {
  describe('AgentTestKit', () => {
    it('exportsVersionedPublicContract', 0, () => {
      expect(AGENT_TESTKIT_VERSION).assertEqual('0.1.0');
      expect(AGENT_TESTKIT_SCHEMA_VERSION).assertEqual('1');
    });

    it('coversEveryArchitectureFaultKind', 0, () => {
      const kinds: FaultKind[] = [
        FaultKind.NETWORK_DISCONNECTED,
        FaultKind.TIMEOUT,
        FaultKind.HTTP_429,
        FaultKind.HTTP_5XX,
        FaultKind.AUTHENTICATION_FAILED,
        FaultKind.PERMISSION_DENIED,
        FaultKind.SCHEMA_DRIFT,
        FaultKind.DUPLICATE_RESPONSE,
        FaultKind.APPLICATION_RESTART,
        FaultKind.BUDGET_EXHAUSTED,
        FaultKind.LOW_QUALITY_OUTPUT,
        FaultKind.IRREVERSIBLE_UNKNOWN_OUTCOME
      ];
      expect(kinds.length).assertEqual(12);
    });

    it('matchesFaultsByTargetPhaseAndOccurrence', 0, () => {
      const script: FaultScript = new FaultScript();
      script.scriptId = 'second-call-timeout';
      script.scriptVersion = '1';
      const timeout: FaultRule = rule('timeout-on-second-call', 2, FaultKind.TIMEOUT);
      timeout.latencyMs = 15000;
      script.rules = [timeout];
      const injector: DeterministicFaultInjector = new DeterministicFaultInjector(script);

      expect(injector.next('provider:model.generate', FaultPhase.DURING_CALL).matched).assertFalse();
      const second = injector.next('provider:model.generate', FaultPhase.DURING_CALL);
      expect(second.matched).assertTrue();
      expect(second.kind).assertEqual(FaultKind.TIMEOUT);
      expect(second.latencyMs).assertEqual(15000);
      expect(injector.next('provider:model.generate', FaultPhase.AFTER_RESPONSE).matched).assertFalse();
    });

    it('resetMakesFaultScheduleReproducible', 0, () => {
      const script: FaultScript = new FaultScript();
      script.scriptId = 'disconnect-first-call';
      script.scriptVersion = '1';
      script.rules = [rule('disconnect', 1, FaultKind.NETWORK_DISCONNECTED)];
      const injector: DeterministicFaultInjector = new DeterministicFaultInjector(script);
      expect(injector.next('provider:model.generate', FaultPhase.DURING_CALL).matched).assertTrue();
      expect(injector.next('provider:model.generate', FaultPhase.DURING_CALL).matched).assertFalse();
      injector.reset();
      expect(injector.next('provider:model.generate', FaultPhase.DURING_CALL).matched).assertTrue();
    });

    it('rejectsAmbiguousOrMalformedFaultMetadata', 0, () => {
      const script: FaultScript = new FaultScript();
      script.scriptId = 'bad-script';
      script.scriptVersion = '1';
      const first: FaultRule = rule('same-rule', 0, FaultKind.HTTP_429);
      first.statusCode = 500;
      const second: FaultRule = rule('same-rule', 1, FaultKind.DUPLICATE_RESPONSE);
      const collision: FaultRule = rule('colliding-schedule', 1, FaultKind.NETWORK_DISCONNECTED);
      script.rules = [first, second, collision];
      const validation = FaultScriptValidator.validate(script);
      expect(validation.valid).assertFalse();
      expect(validation.issues.length).assertEqual(5);
    });

    it('requiresFullyPinnedBenchmarkIdentity', 0, () => {
      const value: BenchmarkManifest = manifest();
      expect(BenchmarkManifestValidator.validate(value).valid).assertTrue();
      value.priceSnapshotDigest = '';
      value.contractSchemaVersion = 'future';
      const invalid = BenchmarkManifestValidator.validate(value);
      expect(invalid.valid).assertFalse();
      expect(invalid.issues.length).assertEqual(2);
    });

    it('requiresSamePermissionAndContextPoliciesAcrossArms', 0, () => {
      const value: BenchmarkManifest = manifest();
      value.arms[1].permissionPolicyVersion = 'broader-policy';
      value.arms[1].contextPolicyVersion = 'larger-context';
      const invalid = BenchmarkManifestValidator.validate(value);
      expect(invalid.valid).assertFalse();
      expect(invalid.issues.length).assertEqual(2);
    });

    it('exportsDeterministicQualityCostLatencyAndRuntimeMetrics', 0, () => {
      const evaluator: BenchmarkEvaluator = new BenchmarkEvaluator(manifest());
      const latencies: number[] = [410, 90, 270, 160, 520];
      for (let index: number = 0; index < latencies.length; index++) {
        const value: BenchmarkSample = sample('case-' + index.toString(), 'run-1',
          index % 2 === 0 ? 'strong-single' : 'multi-agent', latencies[index]);
        value.qualityScoreBasisPoints = 8000 + index * 100;
        if (index === 4) value.passed = false;
        expect(evaluator.record(value).accepted).assertTrue();
      }
      const summary: BenchmarkSummary = evaluator.summarize();
      expect(summary.sampleCount).assertEqual(5);
      expect(summary.passedCount).assertEqual(4);
      expect(summary.failedCount).assertEqual(1);
      expect(summary.averageQualityBasisPoints).assertEqual(8200);
      expect(summary.latencyP50Ms).assertEqual(270);
      expect(summary.latencyP95Ms).assertEqual(520);
      expect(summary.inputTokens).assertEqual(5500);
      expect(summary.outputTokens).assertEqual(1200);
      expect(summary.monetaryCostMicros).assertEqual(16000);
      expect(summary.toolCalls).assertEqual(10);
      expect(summary.agentActivations).assertEqual(7);
      expect(summary.routerDecisions).assertEqual(10);
      expect(summary.routerCorrectDecisions).assertEqual(10);
      expect(evaluator.summarizeArm('strong-single').sampleCount).assertEqual(3);
      expect(evaluator.summarizeArm('multi-agent').sampleCount).assertEqual(2);
      expect(evaluator.report().armSummaries.length).assertEqual(2);
      expect(evaluator.report().armSummaries[0].armId).assertEqual('strong-single');
    });

    it('rejectsInvalidAndDuplicateSamplesWithoutChangingSummary', 0, () => {
      const evaluator: BenchmarkEvaluator = new BenchmarkEvaluator(manifest());
      const first: BenchmarkSample = sample('case-recovery', 'run-8', 'strong-single', 800);
      expect(evaluator.record(first).accepted).assertTrue();
      const duplicate: BenchmarkRecordResult = evaluator.record(first);
      expect(duplicate.accepted).assertFalse();
      const invalid: BenchmarkSample = sample('case-invalid', 'run-8', 'unknown-arm', 200);
      invalid.routerCorrectDecisions = 3;
      invalid.routerDecisions = 2;
      expect(evaluator.record(invalid).issues.length).assertEqual(2);
      expect(evaluator.summarize().sampleCount).assertEqual(1);
    });

    it('copiesInputsAndExportsAConsumerSafeReport', 0, () => {
      const source: BenchmarkManifest = manifest();
      const evaluator: BenchmarkEvaluator = new BenchmarkEvaluator(source);
      source.modelId = 'mutated-model';
      const recorded: BenchmarkSample = sample('case-copy', 'run-3', 'strong-single', 340);
      expect(evaluator.record(recorded).accepted).assertTrue();
      recorded.inputTokens = 999999;
      const json: string = evaluator.reportJson();
      expect(json.includes('fixture-model-balanced')).assertTrue();
      expect(json.includes('mutated-model')).assertFalse();
      expect(json.includes('"inputTokens":1100')).assertTrue();
      expect(json.includes('secret')).assertFalse();
    });

    it('publishesTheTenSharedIntegrationFixtures', 0, () => {
      const fixtures: IntegrationFixtureDescriptor[] = IntegrationFixtureCatalog.baseline();
      expect(fixtures.length).assertEqual(10);
      expect(fixtures[0].kind).assertEqual(IntegrationFixtureKind.INVALID_INPUT);
      expect(fixtures[5].kind).assertEqual(IntegrationFixtureKind.UNKNOWN_WRITE_OUTCOME);
      expect(fixtures[6].requiresProcessRestart).assertTrue();
      expect(fixtures[6].expectedAdapterCalls).assertEqual(1);
      expect(fixtures[9].kind).assertEqual(IntegrationFixtureKind.BUDGET_EXHAUSTED);
    });
  });
}
