import {
  AgentRuntimeEvent,
  AgentTaskSnapshot,
  ClarificationResponse,
  CollaborationMode,
  TaskFrame,
  WorkflowStep
} from '@harmony_agent/agent-contracts';
import {
  PlanningRequest,
  PlanningResult,
  PreparedToolDispatch,
  StepDispatchReceipt,
  StepDispatchRequest
} from './OrchestrationTypes';

export interface RuntimeClockPort {
  nowMs(): number;
}

export interface RuntimeIdGeneratorPort {
  nextId(kind: string, requestId: string): string;
}

export interface CollaborationSelectorPort {
  select(frame: TaskFrame): CollaborationMode;
}

export interface SemanticPlannerPort {
  plan(request: PlanningRequest): PlanningResult;
  resume(request: PlanningRequest, response: ClarificationResponse): PlanningResult;
  replan(request: PlanningRequest): PlanningResult;
}

export interface ToolInvocationPreparerPort {
  prepare(request: PlanningRequest, step: WorkflowStep, nowMs: number): PreparedToolDispatch;
}

export interface StepDispatchPort {
  dispatch(request: StepDispatchRequest): StepDispatchReceipt;
}

/** Internal observation hook used by the production Facade composition root. */
export interface RuntimeStateObserverPort {
  onStateChanged(snapshot: AgentTaskSnapshot, event: AgentRuntimeEvent): void;
}

export class NoopRuntimeStateObserver implements RuntimeStateObserverPort {
  onStateChanged(snapshot: AgentTaskSnapshot, event: AgentRuntimeEvent): void {
  }
}

export class SingleAgentCollaborationSelector implements CollaborationSelectorPort {
  select(frame: TaskFrame): CollaborationMode {
    return CollaborationMode.SINGLE;
  }
}
