#!/usr/bin/env node
// PreToolUse hook for the Chrome navigate tool. Does nothing unless an
// /automation-test run is open (see skills/automation-test/scripts/run-lock.mjs); during a run
// it blocks navigation outside the run's environment (local or dev).
import { checkUrl, LOCK_PATH, readLock } from '../skills/automation-test/scripts/env-rules.mjs';

let input = '';
process.stdin.on('data', (chunk) => (input += chunk));
process.stdin.on('end', () => {
  const lock = readLock();
  if (!lock) process.exit(0);

  let url = '';
  try {
    url = JSON.parse(input).tool_input?.url ?? '';
  } catch {
    process.exit(0);
  }

  const result = checkUrl(String(url), lock);
  if (result.ok) process.exit(0);

  console.error(
    `/automation-test guard: blocked navigation to ${url} (${result.reason}). ` +
      `A ${lock.env} test run for ${lock.project} is open. ` +
      `If no run should be open, end it with: rm ${LOCK_PATH}`,
  );
  process.exit(2);
});
