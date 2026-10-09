import {
  McpAggregateResult,
  McpCapabilityRef,
  McpClientManager,
  McpTool,
  McpToolResult
} from '@harmony_agent/mcp-client';
import { McpClientToolPort } from './McpConnectorTypes';

export class McpClientManagerToolPort implements McpClientToolPort {
  private readonly manager: McpClientManager;

  constructor(manager: McpClientManager) {
    this.manager = manager;
  }

  listTools(): Promise<McpAggregateResult<McpTool>> {
    return this.manager.listTools();
  }

  callTool(ref: McpCapabilityRef, argumentsValue: Object): Promise<McpToolResult> {
    return this.manager.callTool(ref, argumentsValue);
  }
}
