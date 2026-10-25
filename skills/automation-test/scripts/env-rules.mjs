// Shared rules for /automation-test environment guarding. Used by run-lock.mjs (the
// skill) and hooks/guard-env.mjs (the PreToolUse hook), so both enforce the
// same allowlist.
import { existsSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

export const ALLOWED_ENVS = ['local', 'dev'];
export const LOCK_PATH = join(homedir(), '.config', 'alpha', 'test-run.json');
export const LOCK_TTL_MS = 8 * 60 * 60 * 1000;

const LOOPBACK = new Set(['localhost', '127.0.0.1', '[::1]', '::1']);

export function isLoopback(hostname) {
  return LOOPBACK.has(hostname) || hostname.endsWith('.localhost');
}

// Reads the `environments:` block of a profile.yaml: one `key: url` per
// indented line. Commented lines are skipped.
export function parseEnvironments(profileText) {
  const envs = {};
  let inBlock = false;
  for (const line of profileText.split('\n')) {
    if (/^environments:\s*(#.*)?$/.test(line)) {
      inBlock = true;
      continue;
    }
    if (!inBlock) continue;
    if (line.trim() === '' || line.trim().startsWith('#')) continue;
    if (!/^\s/.test(line)) break;
    const m = line.match(/^\s+([A-Za-z_-]+):\s*([^\s#]+)/);
    if (m) envs[m[1]] = m[2];
  }
  return envs;
}

// `localhost:3000/x` has no scheme (its "localhost:" is a host), so only
// `<scheme>://` or a known opaque scheme counts as one.
export function toUrl(raw) {
  const hasScheme =
    /^[a-z][a-z0-9+.-]*:\/\//i.test(raw) || /^(about|javascript|data|blob|vbscript|mailto):/i.test(raw);
  return new URL(hasScheme ? raw : `http://${raw}`);
}

// Decides whether `rawUrl` may be opened under an active lock.
export function checkUrl(rawUrl, lock) {
  if (rawUrl === 'back' || rawUrl === 'forward') return { ok: true };
  if (/^about:blank$/i.test(rawUrl)) return { ok: true };
  let url;
  try {
    url = toUrl(rawUrl);
  } catch {
    return { ok: false, reason: `not a valid URL: ${rawUrl}` };
  }
  if (!['http:', 'https:'].includes(url.protocol)) {
    return { ok: false, reason: `scheme ${url.protocol} is not allowed during a test run` };
  }
  if (lock.env === 'local') {
    return isLoopback(url.hostname)
      ? { ok: true }
      : { ok: false, reason: `env "local" only allows localhost, got ${url.hostname}` };
  }
  if (lock.env === 'dev') {
    return url.hostname === lock.host
      ? { ok: true }
      : { ok: false, reason: `env "dev" only allows ${lock.host}, got ${url.hostname}` };
  }
  return { ok: false, reason: `unknown env ${lock.env}` };
}

export function readLock() {
  if (!existsSync(LOCK_PATH)) return null;
  try {
    const lock = JSON.parse(readFileSync(LOCK_PATH, 'utf8'));
    if (Date.parse(lock.expiresAt) < Date.now()) return null;
    return lock;
  } catch {
    return null;
  }
}
