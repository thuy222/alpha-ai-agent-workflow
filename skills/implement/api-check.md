# Live API check

How `/implement` step 4.2 calls the real API after a BE story. The profile's
`api` block and `notes/implement.md` give the project's concrete values.

## 1. A server running this branch

- Start the API from the branch you are on, on a port nobody else uses
  (`api.start` from the profile with `api.port_env` set to a free port,
  e.g. 5099). A server already listening on the usual port may run an
  older build: don't test against it, and don't stop it (it isn't yours).
- Run it in the background and wait until it answers (any HTTP status).
- Local services the endpoints need (object storage, mail catcher…) come
  from the notes. Start them (`docker compose up -d <service>`) and pass
  their settings as environment variables on the start command. Never edit
  the project's `.env`.
- Apply pending migrations first if the story added any.
- Stop the server (and only it) when done.

## 2. Tokens

- Accounts: `local.accounts.<Role>` in
  `~/.config/alpha/credentials/<project>.yaml`. Values may be quoted YAML
  strings; strip the quotes.
- Log in through the API (`api.login` in the profile) and keep the token in a
  file in the scratchpad. Never print a password or a token in chat or in a
  file inside a repo.
- A role the story needs but the file lacks: say so and test it in the e2e
  suite instead; don't create accounts on the server.

## 3. The script

Write one script per module in the scratchpad (`curl-<module>.sh`) and grow
it with each story, so every run re-checks the earlier stories too. Shape:

```bash
ok()  { [ "$2" == "$3" ] && { PASS=$((PASS+1)); echo "PASS  $1"; } \
        || { FAIL=$((FAIL+1)); echo "FAIL  $1  (expected: $2, got: $3)"; }; }
req() { # TOKEN METHOD PATH [JSON] -> CODE, BODY
  local out; out=$(curl -s -w '\n%{http_code}' -X "$2" -H "Authorization: Bearer $1" \
    -H 'Content-Type: application/json' ${4:+-d "$4"} "$BASE$3")
  CODE=${out##*$'\n'}; BODY=${out%$'\n'*}; }
j()   { echo "$BODY" | jq -r "$1"; }
```

- Create the records each run needs through the API, with a unique tag in
  their names (`CURL-<MODULE> <timestamp>`), so runs don't collide. Report
  the tag; local test data may stay unless the notes say how to purge it.
- For each endpoint: status, the fields the contract promises (exact values,
  not just "200"), the refusals with their `errorCode`, 403 for a role
  without the permission, and that hidden fields are absent (e.g. no prices
  for a technician: assert the key set).
- For each related API: read it before and after the action and assert the
  delta, or assert the exact new value on a record the script owns.
- Multipart uploads: `curl -F "files=@<path>;type=<mime>" -F field=value`.
- End with `PASS n  FAIL m`. Exit code 0 only when `FAIL` is 0.
