/**
 * Example: Operator mode — control worker nodes from a server/desktop.
 *
 * ┌─────────────────────┐         ┌──────────────────┐         ┌──────────────┐
 * │   Your App (this)   │  ws://  │  OpenClaw Gateway │  ws://  │  Worker Node │
 * │                     │ ──────► │    :18789         │ ──────► │  (Android/   │
 * │  OpenClawClient     │         │  routes commands  │         │   RPi/etc)   │
 * │  role: "operator"   │ ◄────── │  to target node   │ ◄────── │              │
 * └─────────────────────┘         └──────────────────┘         └──────────────┘
 *
 * Flow:
 * 1. Connect to gateway with Ed25519 identity
 * 2. First time: gateway shows "pending" — approve with `openclaw devices approve`
 * 3. After approved: list nodes, send commands, receive results
 *
 * Run:
 *   npx tsx examples/operator.ts
 */

import { OpenClawClient, loadOrCreateIdentity } from "../src/index.js";

// ── Setup ──

const identity = loadOrCreateIdentity("./data/operator-identity.json");
console.log(`Device ID: ${identity.deviceId.slice(0, 16)}...`);

const client = new OpenClawClient({
  gatewayUrl: "ws://localhost:18789",
  gatewayToken: process.env.OPENCLAW_GATEWAY_TOKEN ?? "",
  role: "operator",
  scopes: ["operator.admin", "operator.read", "operator.write"],
  identity,
  clientId: "cli",
  clientDisplayName: "Example Operator",
  clientVersion: "0.1.0",
});

// ── Events ──

client.on("connected", async () => {
  console.log("✅ Connected to gateway\n");

  // List all worker nodes
  try {
    const nodes = await client.listNodes();
    console.log(`Found ${nodes.length} node(s):`);
    for (const node of nodes) {
      const status = node.connected ? "🟢" : "🔴";
      console.log(`  ${status} ${node.displayName} (${node.nodeId.slice(0, 12)}...) — ${node.commands?.length ?? 0} commands`);
    }

    if (nodes.length === 0) {
      console.log("\nNo nodes connected. Start a worker node first.");
      client.disconnect();
      return;
    }

    // Send a command to the first connected node
    const target = nodes.find(n => n.connected) ?? nodes[0];
    console.log(`\nSending 'foreground_app' to ${target.displayName}...`);

    const result = await client.invokeNode({
      nodeId: target.nodeId,
      command: "foreground_app",
    });
    console.log(`Result: ${JSON.stringify(result).slice(0, 200)}`);

    // Take a screenshot
    console.log(`\nSending 'screenshot' to ${target.displayName}...`);
    const screenshot = await client.invokeNode({
      nodeId: target.nodeId,
      command: "screenshot",
      params: { quality: 50, maxWidth: 640 },
    });
    const imgLen = (screenshot as Record<string, unknown>).payload;
    console.log(`Screenshot received: ${JSON.stringify(screenshot).length} chars`);

  } catch (e) {
    console.error("Error:", e instanceof Error ? e.message : e);
    // If "pairing required" — first-time setup needed:
    console.log("\n💡 First time? Run on the gateway host:");
    console.log("   openclaw devices list");
    console.log("   openclaw devices approve <requestId>");
  }

  client.disconnect();
});

client.on("disconnected", (code, reason) => {
  console.log(`Disconnected: ${code} ${reason}`);
});

client.on("error", (err) => {
  console.error("WS Error:", err.message);
});

// ── Go ──

client.connect();

// Keep alive for async operations
setTimeout(() => {
  if (client.connected) client.disconnect();
  process.exit(0);
}, 15000);
