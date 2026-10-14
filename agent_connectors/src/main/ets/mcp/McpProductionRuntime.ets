import {
  AgentRuntimeFacade,
  ProductionAgentRuntimeConfig,
  ProductionAgentRuntimePorts,
  ProductionRuntimeAdapterFactoryPort,
  RuntimeToolOutcomeSinkPort,
  SingleAgentCollaborationSelector,
  StepDispatchPort,
  ToolRegistry,
  ToolRegistryEntry,
  createProductionAgentRuntime,
  createRecoveredProductionAgentRuntime
} from '@harmony_agent/agent-runtime';
import { ToolOutcome } from '@harmony_agent/agent-contracts';
import { McpAgentAdapter } from './McpAgentAdapter';
import { McpCatalogRefreshResult, McpToolOutcomeSinkPort } from './McpConnectorTypes';
import { McpStepDispatchAdapter } from './McpStepDispatchAdapter';

function ignoreCompletionRejection(_error: Error): void {
  // ProductionAgentRuntime records its own persistence fault before rejecting the completion Promise.
}

export enum McpRuntimeCompositionErrorCode {
  REGISTRY_NOT_EMPTY = 'REGISTRY_NOT_EMPTY',
  CATALOG_DISCOVERY_FAILED = 'CATALOG_DISCOVERY_FAILED',
  CATALOG_PARTIAL_FAILURE = 'CATALOG_PARTIAL_FAILURE',
  CATALOG_EMPTY = 'CATALOG_EMPTY',
  CATALOG_ENTRY_REJECTED = 'CATALOG_ENTRY_REJECTED'
}

export class McpRuntimeCompositionError extends Error {
  readonly code: McpRuntimeCompositionErrorCode;

  constructor(code: McpRuntimeCompositionErrorCode, message: string) {
    super(message);
    this.name = 'McpRuntimeCompositionError';
    this.code = code;
  }
}

class RuntimeMcpOutcomeSink implements McpToolOutcomeSinkPort {
  private readonly sink: RuntimeToolOutcomeSinkPort;

  constructor(sink: RuntimeToolOutcomeSinkPort) {
    this.sink = sink;
  }

  complete(taskId: string, stepId: string, dispatchId: string, outcome: ToolOutcome): void {
    this.sink.complete(taskId, stepId, dispatchId, outcome).catch(ignoreCompletionRejection);
  }
}

class McpProductionAdapterFactory implements ProductionRuntimeAdapterFactoryPort {
  private readonly adapter: McpAgentAdapter;

  constructor(adapter: McpAgentAdapter) {
    this.adapter = adapter;
  }

  create(sink: RuntimeToolOutcomeSinkPort): StepDispatchPort {
    return new McpStepDispatchAdapter(this.adapter, new RuntimeMcpOutcomeSink(sink));
  }
}

function copyPorts(source: ProductionAgentRuntimePorts, adapter: McpAgentAdapter): ProductionAgentRuntimePorts {
  const value: ProductionAgentRuntimePorts = new ProductionAgentRuntimePorts();
  value.clock = source.clock;
  value.ids = source.ids;
  value.planner = source.planner;
  value.collaboration = new SingleAgentCollaborationSelector();
  value.toolPreparer = source.toolPreparer;
  value.adapterFactory = new McpProductionAdapterFactory(adapter);
  value.persistence = source.persistence;
  value.recovery = source.recovery;
  return value;
}

async function bindCatalog(adapter: McpAgentAdapter, registry: ToolRegistry): Promise<void> {
  if (registry.snapshot().snapshotVersion !== 0) {
    throw new McpRuntimeCompositionError(McpRuntimeCompositionErrorCode.REGISTRY_NOT_EMPTY,
      'MCP production composition requires an empty Tool Registry');
  }
  let refresh: McpCatalogRefreshResult;
  try {
    refresh = await adapter.refreshCatalog();
  } catch (error) {
    throw new McpRuntimeCompositionError(McpRuntimeCompositionErrorCode.CATALOG_DISCOVERY_FAILED,
      'MCP catalog discovery failed');
  }
  if (refresh.failures.length > 0) {
    throw new McpRuntimeCompositionError(McpRuntimeCompositionErrorCode.CATALOG_PARTIAL_FAILURE,
      'MCP catalog discovery returned one or more server failures');
  }
  if (refresh.entries.length === 0) {
    throw new McpRuntimeCompositionError(McpRuntimeCompositionErrorCode.CATALOG_EMPTY,
      'MCP catalog contains no controlled read-only tools');
  }
  const validated: ToolRegistry = new ToolRegistry();
  for (let i: number = 0; i < refresh.entries.length; i++) {
    if (!validated.register(refresh.entries[i]).accepted) {
      throw new McpRuntimeCompositionError(McpRuntimeCompositionErrorCode.CATALOG_ENTRY_REJECTED,
        'MCP catalog contains an invalid or conflicting Tool Registry entry');
    }
  }
  const entries: ToolRegistryEntry[] = validated.activeEntries();
  for (let i: number = 0; i < entries.length; i++) {
    if (!registry.register(entries[i]).accepted) {
      throw new McpRuntimeCompositionError(McpRuntimeCompositionErrorCode.CATALOG_ENTRY_REJECTED,
        'MCP Tool Registry rejected a validated catalog entry');
    }
  }
}

/**
 * Discovers the controlled read-only MCP catalog before exposing the sole task-control Facade.
 * The caller-owned registry may be shared with its planner and tool preparer, but must be empty.
 */
export async function createMcpProductionAgentRuntime(config: ProductionAgentRuntimeConfig,
  ports: ProductionAgentRuntimePorts, adapter: McpAgentAdapter,
  registry: ToolRegistry): Promise<AgentRuntimeFacade> {
  await bindCatalog(adapter, registry);
  return createProductionAgentRuntime(config, copyPorts(ports, adapter));
}

/** Restores durable tasks only after the controlled MCP catalog is discovered and bound. */
export async function createRecoveredMcpProductionAgentRuntime(config: ProductionAgentRuntimeConfig,
  ports: ProductionAgentRuntimePorts, adapter: McpAgentAdapter,
  registry: ToolRegistry): Promise<AgentRuntimeFacade> {
  await bindCatalog(adapter, registry);
  return await createRecoveredProductionAgentRuntime(config, copyPorts(ports, adapter));
}
