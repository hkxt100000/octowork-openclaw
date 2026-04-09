/**
 * Ed25519 device identity for OpenClaw gateway pairing.
 *
 * Protocol:
 * - Key type: Ed25519
 * - deviceId: SHA256(raw_32_byte_public_key) → hex
 * - publicKey: raw 32 bytes → Base64URL
 * - Signature: Ed25519 sign(payload_utf8_bytes) → Base64URL
 * - Payload V3: "v3|deviceId|clientId|clientMode|role|scopes|signedAtMs|token|nonce|platform|deviceFamily"
 */

import { generateKeyPairSync, createPublicKey, createHash, sign } from "crypto";
import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { dirname } from "path";
import type { DeviceIdentityData, DeviceAuth } from "./types.js";

// Ed25519 SPKI DER prefix (12 bytes) — strip to get raw 32 bytes
const ED25519_SPKI_PREFIX = Buffer.from("302a300506032b6570032100", "hex");

/**
 * Load an existing identity from a JSON file, or generate a new one.
 */
export function loadOrCreateIdentity(filePath: string): DeviceIdentityData {
  try {
    const data = JSON.parse(readFileSync(filePath, "utf8")) as DeviceIdentityData;
    if (data.version === 1 && data.deviceId && data.publicKeyPem && data.privateKeyPem) {
      return data;
    }
  } catch {
    // File doesn't exist or is invalid — generate new
  }

  const { publicKey, privateKey } = generateKeyPairSync("ed25519");
  const publicKeyPem = publicKey.export({ type: "spki", format: "pem" }).toString();
  const privateKeyPem = privateKey.export({ type: "pkcs8", format: "pem" }).toString();
  const deviceId = deriveDeviceId(publicKeyPem);

  const data: DeviceIdentityData = {
    version: 1,
    deviceId,
    publicKeyPem,
    privateKeyPem,
    createdAtMs: Date.now(),
  };

  mkdirSync(dirname(filePath), { recursive: true });
  writeFileSync(filePath, JSON.stringify(data, null, 2), { mode: 0o600 });

  return data;
}

/**
 * Derive deviceId from a PEM public key: SHA256(raw_32_bytes) → hex.
 */
export function deriveDeviceId(publicKeyPem: string): string {
  const raw = extractRawPublicKey(publicKeyPem);
  return createHash("sha256").update(raw).digest("hex");
}

/**
 * Get the raw 32-byte public key as Base64URL.
 */
export function publicKeyBase64Url(publicKeyPem: string): string {
  const raw = extractRawPublicKey(publicKeyPem);
  return base64UrlEncode(raw);
}

/**
 * Sign a payload string with Ed25519 private key, return Base64URL signature.
 */
export function signPayload(privateKeyPem: string, payload: string): string {
  const sig = sign(null, Buffer.from(payload, "utf8"), privateKeyPem);
  return base64UrlEncode(sig);
}

/**
 * Build the auth payload V3 string.
 *
 * Format: v3|deviceId|clientId|clientMode|role|scopes|signedAtMs|token|nonce|platform|deviceFamily
 */
export function buildPayloadV3(params: {
  deviceId: string;
  clientId: string;
  clientMode: string;
  role: string;
  scopes: string[];
  signedAtMs: number;
  token: string;
  nonce: string;
  platform: string;
  deviceFamily: string;
}): string {
  return [
    "v3",
    params.deviceId,
    params.clientId,
    params.clientMode,
    params.role,
    params.scopes.sort().join(","),
    String(params.signedAtMs),
    params.token,
    params.nonce,
    params.platform.toLowerCase().trim(),
    params.deviceFamily.toLowerCase().trim(),
  ].join("|");
}

/**
 * Build the signed device auth object for the connect handshake.
 */
export function buildDeviceAuth(
  identity: DeviceIdentityData,
  nonce: string,
  opts: {
    clientId?: string;
    clientMode?: string;
    role?: string;
    scopes?: string[];
    token?: string;
    platform?: string;
    deviceFamily?: string;
  } = {},
): DeviceAuth {
  const signedAtMs = Date.now();
  const payload = buildPayloadV3({
    deviceId: identity.deviceId,
    clientId: opts.clientId ?? "cli",
    clientMode: opts.clientMode ?? "cli",
    role: opts.role ?? "operator",
    scopes: opts.scopes ?? [],
    signedAtMs,
    token: opts.token ?? "",
    nonce,
    platform: opts.platform ?? process.platform,
    deviceFamily: opts.deviceFamily ?? "",
  });

  return {
    id: identity.deviceId,
    publicKey: publicKeyBase64Url(identity.publicKeyPem),
    signature: signPayload(identity.privateKeyPem, payload),
    signedAt: signedAtMs,
    nonce,
  };
}

// ── Helpers ──

function extractRawPublicKey(publicKeyPem: string): Buffer {
  const key = createPublicKey(publicKeyPem);
  const spki = key.export({ type: "spki", format: "der" });
  if (spki.length === 44 && spki.subarray(0, 12).equals(ED25519_SPKI_PREFIX)) {
    return spki.subarray(12);
  }
  return spki;
}

function base64UrlEncode(buf: Buffer): string {
  return buf.toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}
