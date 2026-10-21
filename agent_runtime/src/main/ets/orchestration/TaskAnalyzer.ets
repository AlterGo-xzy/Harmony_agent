import { RiskLevel, TaskEnvelope, TaskFrame } from '@harmony_agent/agent-contracts';

export class TaskAnalyzer {
  analyze(envelope: TaskEnvelope): TaskFrame {
    const frame: TaskFrame = new TaskFrame();
    frame.taskId = envelope.taskId;
    frame.goal = envelope.userIntent.trim();
    frame.constraints = [
      'privacy:' + envelope.privacyClass,
      'locale:' + envelope.locale,
      'timeZone:' + envelope.timeZone,
      'referenceTime:' + envelope.referenceTime
    ];
    let imageInputCount: number = 0;
    for (let index: number = 0; index < envelope.inputRefs.length; index++) {
      if (envelope.inputRefs[index].mediaType.startsWith('image/')) imageInputCount++;
    }
    frame.capabilityCategories = imageInputCount > 0 ? ['image-input'] : [];
    frame.riskLevel = RiskLevel.LOW;
    frame.canParallelize = false;
    frame.featuresJson = '{"inputRefCount":' + envelope.inputRefs.length.toString() +
      ',"imageInputCount":' + imageInputCount.toString() + '}';
    return frame;
  }
}
