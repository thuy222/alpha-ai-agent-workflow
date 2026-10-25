#!/usr/bin/env node
// Opens and closes a /automation-test run. While a run is open, the guard hook (set up by
// install.sh) only lets the browser navigate inside the run's environment.
//
//   node run-lock.mjs start <project> <local|dev> [url]
//   node run-lock.mjs check <url>
//   node run-lock.mjs status
//   node run-lock.mjs stop
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import {
  ALLOWED_ENVS,
  LOCK_PATH,
  LOCK_TTL_MS,
  checkUrl,
  isLoopback,
  parseEnvironments,
  readLock,
  toUrl,
} from './env-rules.mjs';

function fail(message) {
  console.error(`REFUSED: ${message}`);
  process.exit(1);
}

function start(project, env, override) {
  const home = process.env.ALPHA_HOME;
  if (!home) fail('ALPHA_HOME is not set');
  if (!project || !env) fail('usage: start <project> <local|dev> [url]');
  if (!ALLOWED_ENVS.includes(env)) {
    fail(`env "${env}" is not allowed; /automation-test only runs on ${ALLOWED_ENVS.join(' or ')}`);
  }
  const profilePath = join(home, 'projects', project, 'profile.yaml');
  if (!existsSync(profilePath)) fail(`no profile at ${profilePath}`);
  const envs = parseEnvironments(readFileSync(profilePath, 'utf8'));
  const declared = envs[env];

  let url;
  try {
    url = toUrl(override || declared || '');
  } catch {
    fail(`no URL for env "${env}": pass one or declare it under environments in ${profilePath}`);
  }

  let host;
  if (env === 'local') {
    if (!isLoopback(url.hostname)) fail(`env "local" must point at localhost, got ${url.hostname}`);
    host = url.hostname;
  } else {
    if (!declared) fail(`env "dev" is not declared (or is commented out) in ${profilePath}`);
    host = toUrl(declared).hostname;
    if (url.hostname !== host) fail(`env "dev" is ${host}; ${url.hostname} is not allowed`);
  }

  const now = Date.now();
  const lock = {
    project,
    env,
    host,
    baseUrl: url.origin,
    startedAt: new Date(now).toISOString(),
    expiresAt: new Date(now + LOCK_TTL_MS).toISOString(),
  };
  mkdirSync(dirname(LOCK_PATH), { recursive: true });
  writeFileSync(LOCK_PATH, JSON.stringify(lock, null, 2));
  console.log(JSON.stringify({ ok: true, ...lock }));
}

const [cmd, ...args] = process.argv.slice(2);
switch (cmd) {
  case 'start':
    start(...args);
    break;
  case 'check': {
    const lock = readLock();
    if (!lock) fail('no test run is open');
    const result = checkUrl(args[0] ?? '', lock);
    if (!result.ok) fail(result.reason);
    console.log('ALLOWED');
    break;
  }
  case 'status':
    console.log(JSON.stringify(readLock() ?? { open: false }));
    break;
  case 'stop':
    rmSync(LOCK_PATH, { force: true });
    console.log('STOPPED');
    break;
  default:
    fail('usage: run-lock.mjs start|check|status|stop');
}
