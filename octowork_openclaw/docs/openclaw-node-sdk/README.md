# @openclaw/node-sdk

Node.js SDK for the [OpenClaw](https://openclaw.ai) gateway-node protocol.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         OpenClaw Gateway (:18789)                        │
│                                                                          │
│  ┌─────────────┐   WebSocket    ┌────────────────┐   WebSocket          │
│  │  Operator A  │ ◄───────────► │                │ ◄──────────►  Node 1 │
│  │  (your app)  │               │   Challenge    │               (RPi)  │
│  └─────────────┘               │   Response     │                       │
│                                 │   Ed25519      │   WebSocket          │
│  ┌─────────────┐               │   Auth         │ ◄──────────►  Node 2 │
│  │  Operator B  │ ◄───────────► │                │              (Phone) │
│  │  (dashboard) │               │   node.invoke  │                       │
│  └─────────────┘               │   routing      │   WebSocket          │
│                                 │                │ ◄──────────►  Node 3 │
│                                 └────────────────┘              (Linux) │
└──────────────────────────────────────────────────────────────────────────┘

Operator → gateway: "invoke screenshot on Node 2"
Gateway  → Node 2:  event "node.invoke.request" { command: "screenshot" }
Node 2   → Gateway: request "node.invoke.result" { ok: true, image: "..." }
Gateway  → Operator: response { payload: { image: "..." } }
```

### Two Roles

| Role | Who | Can do | Scopes |
|---|---|---|---|
| `operator` | Your app, dashboard, CLI | Send RPC, invoke nodes, list nodes | `operator.admin`, `operator.read`, etc. |
| `node` | Worker devices, IoT, agents | Receive + execute commands, send results | `[]` (none needed) |

## Install

```bash
npm install @openclaw/node-sdk
```

## Quick Start

### Operator mode (send commands to worker nodes)

```typescript
import { OpenClawClient, loadOrCreateIdentity } from "@openclaw/node-sdk";

const identity = loadOrCreateIdentity("./data/identity.json");

const client = new OpenClawClient({
  gatewayUrl: "ws://localhost:18789",
  gatewayToken: "your-gateway-token",
  role: "operator",
  scopes: ["operator.admin", "operator.read", "operator.write"],
  identity,
  clientDisplayName: "My App",
});

client.on("connected", () => console.log("Connected to gateway"));
client.on("disconnected", (code, reason) => console.log(`Disconnected: ${code} ${reason}`));
client.on("event", (event, payload) => console.log(`Event: ${event}`));

client.connect();

// List connected worker nodes
const nodes = await client.listNodes();
console.log("Nodes:", nodes);

// Send command to a worker node
const result = await client.invokeNode({
  nodeId: nodes[0].nodeId,
  command: "screenshot",
  params: { quality: 80 },
});
console.log("Screenshot:", result);
```

### Node mode (receive and execute commands)

```typescript
import { OpenClawClient, loadOrCreateIdentity } from "@openclaw/node-sdk";

const identity = loadOrCreateIdentity("./data/node-identity.json");

const client = new OpenClawClient({
  gatewayUrl: "ws://gateway-host:18789",
  gatewayToken: "your-gateway-token",
  role: "node",
  scopes: [], // nodes have no scopes
  commands: ["screenshot", "tap", "swipe"], // declare supported commands
  identity,
  clientDisplayName: "My Worker Node",
  platform: "linux",

  // Handle incoming commands
  onInvoke: async (command, params) => {
    switch (command) {
      case "screenshot":
        return { image: "base64..." };
      case "tap":
        return { ok: true };
      default:
        throw new Error(`Unknown command: ${command}`);
    }
  },
});

client.on("connected", () => {
  console.log("Registered as node");
  // First time: run `openclaw devices approve <requestId>` on the gateway host
});

client.connect();
```

## Device Identity

Ed25519 key pair for persistent pairing with the gateway. Generated once, stored as a JSON file.

```typescript
import { loadOrCreateIdentity } from "@openclaw/node-sdk";

// Generates on first call, loads on subsequent calls
const identity = loadOrCreateIdentity("./data/identity.json");
console.log("Device ID:", identity.deviceId);
```

First connection requires gateway approval:
```bash
openclaw devices list     # shows pending request
openclaw devices approve <requestId>
```

After approval, the device token is stored and reconnections are automatic.

## API

### `OpenClawClient`

| Method | Description |
|---|---|
| `connect()` | Connect to the gateway WebSocket |
| `disconnect()` | Disconnect and stop reconnecting |
| `request(method, params)` | Send a gateway RPC request |
| `invokeNode(params)` | Send `node.invoke` command to a worker |
| `listNodes()` | List connected worker nodes |
| `send(msg)` | Send raw JSON message |
| `connected` | Whether connected and handshake completed |
| `deviceToken` | Stored device auth token |

### Events

| Event | Args | Description |
|---|---|---|
| `connected` | `(result)` | Handshake completed |
| `disconnected` | `(code, reason)` | Connection closed |
| `event` | `(event, payload)` | Gateway event received |
| `connect:error` | `(error)` | Handshake failed |
| `error` | `(error)` | WebSocket error |

### Identity

| Function | Description |
|---|---|
| `loadOrCreateIdentity(path)` | Load or generate Ed25519 key pair |
| `deriveDeviceId(publicKeyPem)` | SHA256(raw pubkey) → hex |
| `buildDeviceAuth(identity, nonce, opts)` | Build signed device object for connect |
| `buildPayloadV3(params)` | Build pipe-delimited auth payload |

## Protocol Reference

- Role `"operator"`: master/dashboard clients, need scopes for RPC calls
- Role `"node"`: worker devices, zero scopes, receive `node.invoke.request` events, respond via `node.invoke.result`
- Gateway validates Ed25519 signatures on every connect
- Commands must be in `gateway.nodes.allowCommands` config

## Examples

Full runnable examples in `examples/`:

```bash
# Run the operator example (sends commands to nodes)
npx tsx examples/operator.ts

# Run the worker node example (receives and executes commands)
npx tsx examples/worker-node.ts
```

### First-Time Pairing

```
┌──────────┐     1. connect with Ed25519 identity     ┌─────────┐
│  Client   │ ────────────────────────────────────────► │ Gateway │
│           │                                           │         │
│           │     2. "pairing required"                 │         │
│           │ ◄──────────────────────────────────────── │         │
└──────────┘                                           └─────────┘
                                                            │
     3. On gateway host:                                    │
        $ openclaw devices list                             │
        $ openclaw devices approve <requestId>              │
                                                            │
┌──────────┐     4. reconnect → approved!              ┌─────────┐
│  Client   │ ────────────────────────────────────────► │ Gateway │
│           │     5. receives deviceToken               │         │
│           │ ◄──────────────────────────────────────── │         │
│           │     (stored, used for all future connects) │         │
└──────────┘                                           └─────────┘
```

After first approval, reconnections are automatic — no re-approval needed.

## License

MIT
