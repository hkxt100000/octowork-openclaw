/**
 * OpenClaw gateway-node protocol types.
 */

// ── WebSocket Frame Types ──

export interface RequestFrame {
  type: "req";
  id: string;
  method: string;
  params: Record<string, unknown>;
}

export interface ResponseFrame {
  type: "res";
  id: string;
  ok: boolean;
  payload?: Record<string, unknown>;
  error?: { code?: string; message: string; details?: unknown };
}

export interface EventFrame {
  type: "event";
  event: string;
  seq?: number;
  payload?: Record<string, unknown>;
}

export type GatewayFrame = RequestFrame | ResponseFrame | EventFrame;

// ── Connect Handshake ──

export interface ConnectChallenge {
  nonce: string;
}

export interface ConnectParams {
  minProtocol: number;
  maxProtocol: number;
  role: "operator" | "node";
  scopes?: string[];
  client: ClientInfo;
  caps?: string[];
  commands?: string[];
  auth?: ConnectAuth;
  device?: DeviceAuth;
}

export interface ClientInfo {
  id: string;
  displayName?: string;
  version?: string;
  platform?: string;
  deviceFamily?: string;
  mode: string;
  instanceId?: string;
}

export interface ConnectAuth {
  token?: string;
  bootstrapToken?: string;
  deviceToken?: string;
  password?: string;
}

export interface DeviceAuth {
  id: string;
  publicKey: string;
  signature: string;
  signedAt: number;
  nonce: string;
}

export interface ConnectResult {
  auth?: {
    deviceToken?: string;
    role?: string;
    scopes?: string[];
  };
  policy?: {
    tickIntervalMs?: number;
  };
}

// ── Node Invoke ──

export interface NodeInvokeParams {
  nodeId: string;
  command: string;
  params?: Record<string, unknown>;
  idempotencyKey?: string;
  timeoutMs?: number;
}

export interface NodeInvokeRequest {
  id: string;
  nodeId: string;
  command: string;
  paramsJSON?: string;
  params?: Record<string, unknown>;
  timeoutMs?: number;
}

export interface NodeInvokeResultParams {
  id: string;
  nodeId: string;
  ok: boolean;
  payload?: unknown;
  payloadJSON?: string;
  error?: { code?: string; message?: string };
}

export interface NodeInvokeResult {
  ok: boolean;
  nodeId: string;
  command: string;
  payload?: unknown;
  payloadJSON?: string;
}

// ── Node Info ──

export interface NodeInfo {
  nodeId: string;
  displayName?: string;
  platform?: string;
  version?: string;
  clientId?: string;
  clientMode?: string;
  deviceFamily?: string;
  remoteIp?: string;
  caps?: string[];
  commands?: string[];
  connectedAtMs?: number;
  approvedAtMs?: number;
  paired?: boolean;
  connected?: boolean;
}

// ── Device Identity ──

export interface DeviceIdentityData {
  version: number;
  deviceId: string;
  publicKeyPem: string;
  privateKeyPem: string;
  createdAtMs: number;
}

// ── Client Options ──

export interface OpenClawClientOptions {
  /** Gateway WebSocket URL (ws:// or wss://) */
  gatewayUrl: string;
  /** Gateway auth token */
  gatewayToken?: string;
  /** Client role: "operator" for master/dashboard, "node" for worker devices */
  role: "operator" | "node";
  /** Scopes to request. Operators need scopes, nodes use [] */
  scopes?: string[];
  /** Client identifier — must match GATEWAY_CLIENT_IDS */
  clientId?: string;
  /** Display name shown in gateway */
  clientDisplayName?: string;
  /** Client version string */
  clientVersion?: string;
  /** Client platform (e.g., "darwin", "linux", "android") */
  platform?: string;
  /** Device family (e.g., "mobile", "desktop") */
  deviceFamily?: string;
  /** Client mode — must match GATEWAY_CLIENT_MODES */
  clientMode?: string;
  /** Capabilities this client supports */
  caps?: string[];
  /** Commands this node supports (node mode only) */
  commands?: string[];
  /** Device identity for persistent pairing */
  identity?: DeviceIdentityData;
  /** Handler for incoming node.invoke.request (node mode only) */
  onInvoke?: (command: string, params: Record<string, unknown>) => Promise<unknown>;
  /** Reconnection base delay in ms (default 1000) */
  reconnectBaseMs?: number;
  /** Max reconnection delay in ms (default 30000) */
  reconnectMaxMs?: number;
  /** Request timeout in ms (default 30000) */
  requestTimeoutMs?: number;
}
