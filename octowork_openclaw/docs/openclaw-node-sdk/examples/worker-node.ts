/**
 * Example: Worker node mode — receive and execute commands from the gateway.
 *
 * ┌──────────────────┐         ┌──────────────────┐         ┌─────────────────┐
 * │  Operator / CLI  │  ws://  │  OpenClaw Gateway │  ws://  │  This Worker    │
 * │                  │ ──────► │    :18789         │ ──────► │  (this script)  │
 * │  "screenshot"    │         │  finds node by ID │         │                 │
 * │                  │ ◄────── │  routes command   │ ◄────── │  executes cmd   │
 * │  ← result image  │         │  returns result   │         │  returns result │
 * └──────────────────┘         └──────────────────┘         └─────────────────┘
 *
 * The worker:
 * 1. Connects with role="node", scopes=[]
 * 2. Declares what commands it supports
 * 3. Gateway registers it in nodeRegistry
 * 4. First time: needs `openclaw devices approve` on gateway host
 * 5. Receives node.invoke.request events, executes, returns results
 *
 * Run:
 *   npx tsx examples/worker-node.ts
 */

import { OpenClawClient, loadOrCreateIdentity } from "../src/index.js";
import { execSync } from "child_process";
import { hostname } from "os";

// ── Setup ──

const identity = loadOrCreateIdentity("./data/worker-identity.json");
console.log(`Worker ID: ${identity.deviceId.slice(0, 16)}...`);

const client = new OpenClawClient({
  gatewayUrl: process.env.GATEWAY_URL ?? "ws://localhost:18789",
  gatewayToken: process.env.OPENCLAW_GATEWAY_TOKEN ?? "",
  role: "node",           // <── NODE role, not operator
  scopes: [],             // <── nodes have ZERO scopes
  commands: [             // <── declare what this node can do
    "ping",
    "hostname",
    "shell",
    "screenshot",
  ],
  identity,
  clientId: "node-host",
  clientDisplayName: `Worker (${hostname()})`,
  platform: process.platform,

  // ── Command Handler ──
  // This is called when the gateway routes a node.invoke to us
  onInvoke: async (command, params) => {
    console.log(`📥 Received: ${command} ${JSON.stringify(params)}`);

    switch (command) {
      case "ping":
        return { pong: true, timestamp: Date.now() };

      case "hostname":
        return { hostname: hostname(), platform: process.platform };

      case "shell": {
        // Execute a shell command (be careful with this in production!)
        const cmd = params.command as string;
        if (!cmd) throw new Error("missing command param");
        try {
          const output = execSync(cmd, { encoding: "utf8", timeout: 10000 });
          return { ok: true, output: output.trim() };
        } catch (e) {
          return { ok: false, error: e instanceof Error ? e.message : String(e) };
        }
      }

      case "screenshot":
        // Simulated — a real worker would capture the screen
        return { image: "base64-placeholder", format: "jpeg" };

      default:
        throw new Error(`Unknown command: ${command}`);
    }
  },
});

// ── Events ──

client.on("connected", () => {
  console.log("✅ Registered as worker node");
  console.log("   Waiting for commands...\n");
  console.log("   💡 Send a command from operator:");
  console.log(`   openclaw gateway call node.invoke --json --params '{"nodeId":"${identity.deviceId}","idempotencyKey":"test","command":"ping"}'`);
  console.log();
});

client.on("disconnected", (code, reason) => {
  if (reason.includes("pairing")) {
    console.log("\n💡 First time pairing needed. Run on the gateway host:");
    console.log("   openclaw devices approve");
  } else {
    console.log(`Disconnected: ${code} ${reason}`);
  }
});

client.on("event", (event, payload) => {
  if (event !== "health" && event !== "tick") {
    console.log(`Event: ${event}`);
  }
});

// ── Go ──

console.log("Connecting to gateway...\n");
client.connect();

// Keep running (worker stays alive)
process.on("SIGINT", () => {
  console.log("\nShutting down...");
  client.disconnect();
  process.exit(0);
});
