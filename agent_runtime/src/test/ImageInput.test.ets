import { describe, expect, it } from '@ohos/hypium';
import {
  AgentTaskSnapshot,
  AuthorizationDecision,
  ClarificationResponse,
  CommandReceipt,
  ReconciliationReport,
  TaskControlCommand,
  TaskEnvelope,
  TaskHandle,
  TaskInputRef,
  TaskSubmission
} from '@harmony_agent/agent-contracts';
import {
  AGENT_FRONTEND_MAX_IMAGE_INPUTS,
  AgentApplicationBackend,
  AgentApplicationBackendConfig,
  AgentApplicationBackendError,
  AgentApplicationBackendErrorCode,
  AgentApplicationBackendIdentityPort,
  AgentFrontendImageInput,
  AgentFrontendTaskRequest,
  AgentRuntimeFacade,
  AgentRuntimeObserver,
  AgentSubscription,
  ShutdownMode,
  SingleAgentHostPorts,
  SingleAgentHostResourcePort,
  SingleAgentHostRuntimeFactoryPort,
  SubscriptionRequest
} from '../../Index';
import { TaskAnalyzer } from '../main/ets/orchestration/TaskAnalyzer';

class ImageInputResource implements SingleAgentHostResourcePort {
  async open(): Promise<void> {}
  async close(): Promise<void> {}
}

class ImageInputFacade implements AgentRuntimeFacade {
  submission?: TaskSubmission;

  async submitTask(submission: TaskSubmission): Promise<TaskHandle> {
    this.submission = submission;
    const handle: TaskHandle = new TaskHandle();
    handle.requestId = submission.requestId;
    handle.taskId = 'task-image';
    handle.sessionId = 'session-image';
    handle.acceptedAt = submission.submittedAt;
    return handle;
  }

  async getTaskSnapshot(_taskId: string): Promise<AgentTaskSnapshot> { throw new Error('unused'); }
  async cancelTask(_command: TaskControlCommand): Promise<CommandReceipt> { throw new Error('unused'); }
  async pauseTask(_command: TaskControlCommand): Promise<CommandReceipt> { throw new Error('unused'); }
  async resumeTask(_command: TaskControlCommand): Promise<CommandReceipt> { throw new Error('unused'); }
  async provideAuthorization(_decision: AuthorizationDecision): Promise<CommandReceipt> { throw new Error('unused'); }
  async provideClarification(_response: ClarificationResponse): Promise<CommandReceipt> { throw new Error('unused'); }
  async provideReconciliation(_report: ReconciliationReport): Promise<CommandReceipt> { throw new Error('unused'); }
  async subscribe(_request: SubscriptionRequest, _observer: AgentRuntimeObserver): Promise<AgentSubscription> {
    throw new Error('unused');
  }
  async shutdown(_mode: ShutdownMode): Promise<void> {}
}

class ImageInputRuntimeFactory implements SingleAgentHostRuntimeFactoryPort {
  readonly facade: ImageInputFacade = new ImageInputFacade();
  async create(): Promise<AgentRuntimeFacade> { return this.facade; }
}

class ImageInputIdentity implements AgentApplicationBackendIdentityPort {
  nextId(scope: string): string { return scope + '-image'; }
  nowMs(): number { return 1792537200000; }
}

class ImageInputFixture {
  readonly factory: ImageInputRuntimeFactory = new ImageInputRuntimeFactory();
  readonly backend: AgentApplicationBackend;

  constructor() {
    const ports: SingleAgentHostPorts = new SingleAgentHostPorts();
    ports.credentialStore = new ImageInputResource();
    ports.executionStorage = new ImageInputResource();
    ports.memoryStorage = new ImageInputResource();
    ports.mcpClient = new ImageInputResource();
    ports.runtimeFactory = this.factory;
    const config: AgentApplicationBackendConfig = new AgentApplicationBackendConfig();
    config.userId = 'image-user';
    this.backend = new AgentApplicationBackend(config, ports, new ImageInputIdentity());
  }
}

function image(refId: string = 'image-1', mediaType: string = 'image/jpeg'): AgentFrontendImageInput {
  const value: AgentFrontendImageInput = new AgentFrontendImageInput();
  value.refId = refId;
  value.mediaType = mediaType;
  value.digest = 'sha256:' + 'a'.repeat(64);
  value.source = 'attachment://' + refId;
  return value;
}

async function rejectionCode(backend: AgentApplicationBackend,
  request: AgentFrontendTaskRequest): Promise<AgentApplicationBackendErrorCode | undefined> {
  try {
    await backend.submitTask(request);
  } catch (error) {
    if (error instanceof AgentApplicationBackendError) return error.code;
  }
  return undefined;
}

export default function imageInputTest(): void {
  describe('ImageInput', () => {
    it('copiesStagedImageReferencesIntoTaskSubmission', 0, async () => {
      const fixture: ImageInputFixture = new ImageInputFixture();
      await fixture.backend.onCreate();
      const request: AgentFrontendTaskRequest = new AgentFrontendTaskRequest();
      request.intent = '描述这张图片';
      request.images = [image()];

      await fixture.backend.submitTask(request);

      const submission: TaskSubmission | undefined = fixture.factory.facade.submission;
      expect(submission !== undefined).assertTrue();
      if (submission === undefined) return;
      expect(submission.inputRefs.length).assertEqual(1);
      expect(submission.inputRefs[0].refId).assertEqual('image-1');
      expect(submission.inputRefs[0].mediaType).assertEqual('image/jpeg');
      expect(submission.inputRefs[0].source).assertEqual('attachment://image-1');
      request.images[0].refId = 'mutated';
      expect(submission.inputRefs[0].refId).assertEqual('image-1');
      await fixture.backend.onDestroy();
    });

    it('rejectsUntrustedDuplicateAndExcessImageReferences', 0, async () => {
      const fixture: ImageInputFixture = new ImageInputFixture();
      await fixture.backend.onCreate();
      const untrusted: AgentFrontendTaskRequest = new AgentFrontendTaskRequest();
      untrusted.intent = '描述图片';
      untrusted.images = [image()];
      untrusted.images[0].source = 'file:///data/storage/el2/base/private/image.jpg';
      expect(await rejectionCode(fixture.backend, untrusted)).assertEqual(
        AgentApplicationBackendErrorCode.INVALID_REQUEST);

      const duplicate: AgentFrontendTaskRequest = new AgentFrontendTaskRequest();
      duplicate.intent = '比较图片';
      duplicate.images = [image(), image()];
      expect(await rejectionCode(fixture.backend, duplicate)).assertEqual(
        AgentApplicationBackendErrorCode.INVALID_REQUEST);

      const excess: AgentFrontendTaskRequest = new AgentFrontendTaskRequest();
      excess.intent = '比较图片';
      excess.images = [];
      for (let index: number = 0; index <= AGENT_FRONTEND_MAX_IMAGE_INPUTS; index++) {
        excess.images.push(image('image-' + index.toString()));
      }
      expect(await rejectionCode(fixture.backend, excess)).assertEqual(
        AgentApplicationBackendErrorCode.INVALID_REQUEST);
      await fixture.backend.onDestroy();
    });

    it('marksImageInputsForPlanningWithoutEmbeddingImageBytes', 0, () => {
      const envelope: TaskEnvelope = new TaskEnvelope();
      envelope.taskId = 'task-image';
      envelope.userIntent = '识别图片内容';
      const input: TaskInputRef = new TaskInputRef();
      input.refId = 'image-1';
      input.mediaType = 'image/png';
      input.digest = 'sha256:' + 'b'.repeat(64);
      input.source = 'attachment://image-1';
      envelope.inputRefs = [input];

      const analyzer: TaskAnalyzer = new TaskAnalyzer();
      const features: string = analyzer.analyze(envelope).featuresJson;
      expect(features).assertEqual('{"inputRefCount":1,"imageInputCount":1}');
      expect(analyzer.analyze(envelope).capabilityCategories[0]).assertEqual('image-input');
    });
  });
}
