/**
 * @openclaw/node-sdk — Node.js SDK for OpenClaw gateway-node protocol.
 *
 * Usage:
 *
 * ```typescript
 * import { OpenClawClient, loadOrCreateIdentity } from "@openclaw/node-sdk";
 *
 * const identity = loadOrCreateIdentity("./data/identity.json");
 *
 * const client = new OpenClawClient({
 *   gatewayUrl: "ws://localhost:18789",
 *   gatewayToken: "your-token",
 *   role: "operator",
 *   scopes: ["operator.admin", "operator.read", "operator.write"],
 *   identity,
 * });
 *
 * client.on("connected", () => console.log("Connected!"));
 * client.connect();
 *
 * const result = await client.invokeNode({
 *   nodeId: "abc...",
 *   command: "screenshot",
 * });
 * ```
 */

export { OpenClawClient } from "./client.js";

export {
  loadOrCreateIdentity,
  deriveDeviceId,
  publicKeyBase64Url,
  signPayload,
  buildPayloadV3,
  buildDeviceAuth,
} from "./identity.js";

export type {
  OpenClawClientOptions,
  ConnectParams,
  ConnectAuth,
  ConnectResult,
  ClientInfo,
  DeviceAuth,
  DeviceIdentityData,
  NodeInvokeParams,
  NodeInvokeRequest,
  NodeInvokeResult,
  NodeInvokeResultParams,
  NodeInfo,
  RequestFrame,
  ResponseFrame,
  EventFrame,
  GatewayFrame,
} from "./types.js";
