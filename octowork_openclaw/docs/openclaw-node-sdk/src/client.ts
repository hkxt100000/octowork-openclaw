/**
 * OpenClaw Gateway WebSocket Client.
 *
 * Handles:
 * - Challenge-response handshake with Ed25519 device identity
 * - Request-response pattern with timeouts
 * - Event listening (health, tick, node.invoke.request)
 * - Auto-reconnection with exponential backoff
 * - Both "operator" and "node" roles
 */

import WebSocket from "ws";
import { EventEmitter } from "events";
import { buildDeviceAuth } from "./identity.js";
import type {
  OpenClawClientOptions,
  ConnectParams,
  NodeInvokeParams,
  NodeInvokeRequest,
  NodeInvokeResultParams,
  NodeInfo,
  DeviceAuth,
} from "./types.js";

export class OpenClawClient extends EventEmitter {
  private ws: WebSocket | null = null;
  private opts: Required<
    Pick<OpenClawClientOptions, "gatewayUrl" | "role" | "clientMode">
  > & OpenClawClientOptions;
  private pendingRequests = new Map<string, {
    resolve: (data: Record<string, unknown>) => void;
    reject: (err: Error) => void;
    timeout: ReturnType<typeof setTimeout>;
  }>();
  private requestCounter = 0;
  private reconnectDelay: number;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private handshakeCompleted = false;
  private _connected = false;
  private _closed = false;
  private storedDeviceToken: string | null = null;

  constructor(opts: OpenClawClientOptions) {
    super();
    this.opts = {
      ...opts,
      clientId: opts.clientId ?? (opts.role === "node" ? "node-host" : "cli"),
      clientMode: opts.clientMode ?? (opts.role === "node" ? "node" : "cli"),
      scopes: opts.scopes ?? (opts.role === "node" ? [] : ["operator.admin"]),
      caps: opts.caps ?? [],
      commands: opts.commands ?? [],
      platform: opts.platform ?? process.platform,
      deviceFamily: opts.deviceFamily ?? "",
      clientVersion: opts.clientVersion ?? "0.1.0",
      reconnectBaseMs: opts.reconnectBaseMs ?? 1000,
      reconnectMaxMs: opts.reconnectMaxMs ?? 30000,
      requestTimeoutMs: opts.requestTimeoutMs ?? 30000,
    };
    this.reconnectDelay = this.opts.reconnectBaseMs!;
  }

  /** Whether the client is connected and handshake completed. */
  get connected(): boolean { return this._connected; }

  /** Store a device token received after pairing (for reconnection). */
  set deviceToken(token: string | null) { this.storedDeviceToken = token; }
  get deviceToken(): string | null { return this.storedDeviceToken; }

  /**
   * Connect to the gateway.
   */
  connect(): void {
    if (this._closed) return;
    this.handshakeCompleted = false;

    const ws = new WebSocket(this.opts.gatewayUrl);
    this.ws = ws;

    ws.on("open", () => {
      this.emit("ws:open");
    });

    ws.on("message", (data: WebSocket.Data) => {
      try {
        const msg = JSON.parse(data.toString());
        this.handleMessage(msg);
      } catch {
        // non-JSON
      }
    });

    ws.on("close", (code: number, reason: Buffer) => {
      const reasonStr = reason.toString();
      this._connected = false;
      this.handshakeCompleted = false;
      this.emit("disconnected", code, reasonStr);
      this.scheduleReconnect();
    });

    ws.on("error", (err: Error) => {
      this.emit("error", err);
    });
  }

  /**
   * Disconnect and stop reconnecting.
   */
  disconnect(): void {
    this._closed = true;
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    this.flushPending(new Error("client disconnected"));
    this.ws?.close(1000, "client disconnect");
    this.ws = null;
    this._connected = false;
  }

  /**
   * Send a gateway RPC request and wait for the response.
   */
  async request(method: string, params: Record<string, unknown> = {}): Promise<Record<string, unknown>> {
    const id = this.nextId();
    return new Promise((resolve, reject) => {
      const timeoutMs = this.opts.requestTimeoutMs!;
      const timeout = setTimeout(() => {
        this.pendingRequests.delete(id);
        reject(new Error(`Request ${method} timed out after ${timeoutMs}ms`));
      }, timeoutMs);

      this.pendingRequests.set(id, { resolve, reject, timeout });
      this.send({ type: "req", id, method, params });
    });
  }

  /**
   * Invoke a command on a worker node via the gateway.
   */
  async invokeNode(params: NodeInvokeParams): Promise<Record<string, unknown>> {
    const result = await this.request("node.invoke", {
      nodeId: params.nodeId,
      command: params.command,
      params: params.params ?? {},
      idempotencyKey: params.idempotencyKey ?? this.nextId(),
      ...(params.timeoutMs ? { timeoutMs: params.timeoutMs } : {}),
    });
    return result;
  }

  /**
   * List connected nodes (requires operator role with admin scope).
   */
  async listNodes(): Promise<NodeInfo[]> {
    const result = await this.request("node.list", {});
    return (result.nodes as NodeInfo[]) ?? [];
  }

  /**
   * Send a raw JSON message on the WebSocket.
   */
  send(msg: Record<string, unknown>): boolean {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(msg));
      return true;
    }
    return false;
  }

  // ── Message Handling ──

  private handleMessage(msg: Record<string, unknown>): void {
    const type = msg.type as string;

    switch (type) {
      case "event":
        this.handleEvent(msg);
        break;
      case "res":
        this.handleResponse(msg);
        break;
      default:
        this.emit("message", msg);
    }
  }

  private handleEvent(msg: Record<string, unknown>): void {
    const event = msg.event as string;
    const payload = msg.payload as Record<string, unknown> | undefined;

    switch (event) {
      case "connect.challenge": {
        const nonce = (payload?.nonce as string)?.trim();
        if (!nonce) {
          this.ws?.close(1008, "missing nonce");
          return;
        }
        this.sendConnect(nonce);
        break;
      }

      case "node.invoke.request": {
        if (payload && this.opts.onInvoke) {
          this.handleNodeInvoke(payload);
        }
        break;
      }

      case "tick":
        break;

      default:
        this.emit("event", event, payload);
    }
  }

  private handleResponse(msg: Record<string, unknown>): void {
    const id = msg.id as string;
    const pending = this.pendingRequests.get(id);
    if (!pending) return;

    this.pendingRequests.delete(id);
    clearTimeout(pending.timeout);

    if (msg.ok) {
      pending.resolve((msg.payload as Record<string, unknown>) ?? {});
    } else {
      const error = msg.error as Record<string, unknown> | undefined;
      pending.reject(new Error(
        `${error?.code ?? "ERROR"}: ${error?.message ?? "unknown error"}`
      ));
    }
  }

  // ── Node Invoke Handler (node mode) ──

  private async handleNodeInvoke(payload: Record<string, unknown>): Promise<void> {
    const requestId = payload.id as string;
    const nodeId = payload.nodeId as string;
    const command = payload.command as string;
    const paramsJSON = payload.paramsJSON as string | undefined;

    const params = paramsJSON
      ? (JSON.parse(paramsJSON) as Record<string, unknown>)
      : (payload.params as Record<string, unknown>) ?? {};

    try {
      const result = await this.opts.onInvoke!(command, params);
      await this.request("node.invoke.result", {
        id: requestId,
        nodeId,
        ok: true,
        payloadJSON: JSON.stringify(result),
      });
    } catch (e) {
      await this.request("node.invoke.result", {
        id: requestId,
        nodeId,
        ok: false,
        error: { code: "COMMAND_FAILED", message: e instanceof Error ? e.message : String(e) },
      });
    }
  }

  // ── Connect Handshake ──

  private sendConnect(nonce: string): void {
    const device = this.buildDeviceAuth(nonce);

    const params: ConnectParams = {
      minProtocol: 3,
      maxProtocol: 3,
      role: this.opts.role,
      scopes: this.opts.scopes,
      client: {
        id: this.opts.clientId!,
        displayName: this.opts.clientDisplayName,
        version: this.opts.clientVersion,
        platform: this.opts.platform,
        deviceFamily: this.opts.deviceFamily,
        mode: this.opts.clientMode!,
      },
      caps: this.opts.caps,
      commands: this.opts.commands,
      auth: {
        ...(this.storedDeviceToken ? { deviceToken: this.storedDeviceToken } : {}),
        ...(this.opts.gatewayToken ? { token: this.opts.gatewayToken } : {}),
      },
      ...(device ? { device } : {}),
    };

    this.request("connect", params as unknown as Record<string, unknown>)
      .then((result) => {
        this.handshakeCompleted = true;
        this._connected = true;
        this.reconnectDelay = this.opts.reconnectBaseMs!;

        // Store device token for future reconnects
        const auth = result.auth as Record<string, unknown> | undefined;
        if (auth?.deviceToken) {
          this.storedDeviceToken = auth.deviceToken as string;
        }

        this.emit("connected", result);
      })
      .catch((err) => {
        this.emit("connect:error", err);
      });
  }

  private buildDeviceAuth(nonce: string): DeviceAuth | undefined {
    if (!this.opts.identity) return undefined;

    return buildDeviceAuth(this.opts.identity, nonce, {
      clientId: this.opts.clientId,
      clientMode: this.opts.clientMode,
      role: this.opts.role,
      scopes: this.opts.scopes,
      token: this.opts.gatewayToken ?? "",
      platform: this.opts.platform,
      deviceFamily: this.opts.deviceFamily,
    });
  }

  // ── Reconnection ──

  private scheduleReconnect(): void {
    if (this._closed) return;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectDelay = Math.min(this.reconnectDelay * 2, this.opts.reconnectMaxMs!);
      this.connect();
    }, this.reconnectDelay);
  }

  private flushPending(err: Error): void {
    for (const [, p] of this.pendingRequests) {
      clearTimeout(p.timeout);
      p.reject(err);
    }
    this.pendingRequests.clear();
  }

  private nextId(): string {
    return `sdk-${++this.requestCounter}-${Date.now()}`;
  }
}
