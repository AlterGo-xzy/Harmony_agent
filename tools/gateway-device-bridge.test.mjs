import assert from 'node:assert/strict';
import http from 'node:http';
import test from 'node:test';
import {
  DEVICE_BRIDGE_AUTHORIZATION,
  startGatewayDeviceBridge
} from './gateway-device-bridge.mjs';

function listen(server) {
  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => resolve(server.address().port));
  });
}

function close(server) {
  return new Promise((resolve, reject) => {
    server.close((error) => error === undefined ? resolve() : reject(error));
  });
}

test('device bridge replaces the non-secret marker and records only safe counters', async () => {
  const gatewayToken = 'upstream-secret-for-test';
  let upstreamCalls = 0;
  const upstream = http.createServer((request, response) => {
    upstreamCalls++;
    if (request.url === '/ready') {
      assert.equal(request.headers.authorization, undefined);
      response.writeHead(200, { 'content-type': 'application/json' });
      response.end('{"ready":true}');
      return;
    }
    assert.equal(request.url, '/v1/chat/completions');
    assert.equal(request.headers.authorization, `Bearer ${gatewayToken}`);
    response.writeHead(200, { 'content-type': 'application/json' });
    response.end('{"choices":[{"message":{"content":"HARMONY_AGENT_DEVICE_OK"},"finish_reason":"stop"}],"usage":{"prompt_tokens":3,"completion_tokens":4,"total_tokens":7}}');
  });
  const upstreamPort = await listen(upstream);
  const bridge = await startGatewayDeviceBridge({
    gatewayBaseUrl: `http://127.0.0.1:${upstreamPort}`,
    gatewayToken
  });
  try {
    const rejected = await fetch(`http://127.0.0.1:${bridge.port}/v1/chat/completions`, {
      method: 'POST',
      headers: { authorization: 'Bearer wrong-device-marker', 'content-type': 'application/json' },
      body: '{}'
    });
    assert.equal(rejected.status, 401);
    assert.equal(upstreamCalls, 0);

    const ready = await fetch(`http://127.0.0.1:${bridge.port}/ready`);
    assert.equal(ready.status, 200);
    const chat = await fetch(`http://127.0.0.1:${bridge.port}/v1/chat/completions`, {
      method: 'POST',
      headers: { authorization: DEVICE_BRIDGE_AUTHORIZATION, 'content-type': 'application/json' },
      body: '{"model":"aigw/default"}'
    });
    assert.equal(chat.status, 200);
    const body = await chat.text();
    assert.match(body, /HARMONY_AGENT_DEVICE_OK/);
    assert.equal(upstreamCalls, 2);
    assert.deepEqual(bridge.summary.upstreamStatusCounts, { '200': 2 });
    assert.equal(bridge.summary.gatewayCredentialRecorded, false);
    assert.equal(bridge.summary.requestBodyRecorded, false);
    assert.equal(bridge.summary.responseBodyRecorded, false);
    assert.equal(JSON.stringify(bridge.summary).includes(gatewayToken), false);
  } finally {
    await bridge.close();
    await close(upstream);
  }
});

test('device bridge rejects remote upstream URLs and oversized requests', async () => {
  await assert.rejects(() => startGatewayDeviceBridge({
    gatewayBaseUrl: 'https://example.com/v1',
    gatewayToken: 'test-only'
  }), /HTTP loopback/);

  const upstream = http.createServer((_request, response) => response.end('{}'));
  const upstreamPort = await listen(upstream);
  const bridge = await startGatewayDeviceBridge({
    gatewayBaseUrl: `http://127.0.0.1:${upstreamPort}/v1`,
    gatewayToken: 'test-only',
    maxRequestBytes: 4
  });
  try {
    const response = await fetch(`http://127.0.0.1:${bridge.port}/v1/chat/completions`, {
      method: 'POST',
      headers: { authorization: DEVICE_BRIDGE_AUTHORIZATION, 'content-type': 'application/json' },
      body: '12345'
    });
    assert.equal(response.status, 413);
    assert.equal(bridge.summary.chatCount, 0);
  } finally {
    await bridge.close();
    await close(upstream);
  }
});
