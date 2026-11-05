# alpha-fullstack

A set of Claude Code skills shared by every Alpha Bravo project. You call a
slash command with a project name and a request (or a document). The skill
reads the project's profile and works in the right repo under `../projects/`.

```
/work woodcraft docs/BA/purchase-orders.pdf
/plan shamrock schedule fe
/implement woodcraft purchase-orders be US02
/automation-test shamrock work-orders smoke env=local
```

## Skills

| Command | What it does |
| --- | --- |
| `/work <project> <request>` | Common entry point: classifies the request and runs the matching skill (or makes a small change directly) |
| `/plan` | Plans BE/FE from the BA user stories, Lovable and the existing code, with open questions. Writes no code |
| `/db-design` | Designs or documents the DB, confirms the sources are the latest, with an independent reviewer |
| `/implement` | Codes an agreed plan: creates a branch, codes story by story, checks, reviews, commits (no push unless asked) |
| `/review` | Read-only review by the `alpha-code-reviewer` agent (plus a design diff by `alpha-lovable-reader` for FE) |
| `/how-to-verify` | Writes a manual verification guide `docs/plans/<module>.verify.md` |
| `/automation-test` | Runs the verify guide's scenarios in Chrome, **local/dev only**, and writes a report |
| `/generate-daily-report` | Planned day-by-day report for a module (FE/BE/API integration) from the plans and BA doc, copied to the clipboard for Slack |

Agents: `alpha-code-reviewer`, `alpha-db-design-reviewer`,
`alpha-lovable-reader`. They carry a prefix because a project repo may have an
agent with the same base name (`code-reviewer`), and the project's agent would
win.

### Making the code match the Lovable design

`alpha-lovable-reader` reads Lovable at one fixed commit, every file to the
end, plus the prompt history. It has two modes:

- `spec`: writes `docs/plans/<module>.lovable.md` with the tokens (colours as
  hex, radius, fonts), the shadcn primitives resolved to values, and every
  element of every screen (`E1.03`): its original classes with `file:line`,
  px/hex values, position, exact text, icon, states, format, behaviour and
  roles. It also lists prompts "not in code", Lovable bugs, and
  `design-checks` blocks (JSON) to measure against.
- `compare`: checks the local code against the spec property by property and
  returns a `DD1, DD2…` table.

Where it runs:

- `/plan` (FE): always runs `spec`. The plan's UI spec points at element ids.
- `/implement` (FE): codes to the spec's values, not to antd's defaults.
  Before review it must run `compare`, then `shared/design-check.js` in
  Chrome on the local app (`getComputedStyle`) until every check passes.
- `/review` (FE): runs `compare` in parallel with `alpha-code-reviewer`.
- `/how-to-verify`: the "Look matches Lovable" scenario runs the
  `design-checks`.

### Name clashes with built-in commands

These are personal skills, so they **replace** Claude Code commands with the
same name in the local terminal:

- `/plan` replaces the built-in "enter plan mode". Use `Shift+Tab` to enter
  plan mode.
- Claude Code's `/review` is an alias of `/code-review`. The docs don't say
  whether a personal skill overrides an alias. If `/review` still opens
  Claude Code's code review, rename the `skills/review` folder (e.g. to `cr`)
  and re-run `./install.sh`.
- `/db-design` and `/how-to-verify` share their names with skills committed
  in the shamrock and woodcraft-be repos.

## Install (once per machine)

```bash
./install.sh
```

The script does three things:
- symlinks `skills/*` into `~/.claude/skills/` and `agents/*.md` into
  `~/.claude/agents/`;
- adds `ALPHA_HOME` to `~/.claude/settings.json`;
- adds the `/automation-test` guard hook to the same file.

Settings are backed up next to the original before any change. The script is
safe to re-run. Uninstall with `./uninstall.sh`. Restart Claude Code after
installing.

Because these are symlinks, edits to skills, profiles or notes in this repo
apply from the next session. No reinstall is needed unless you add a new
skill or agent.

Test accounts for `/automation-test`: copy
`skills/automation-test/credentials.example.yaml` to
`~/.config/alpha/credentials/<project>.yaml`, fill it in, then `chmod 600`.
This file must **never** be in the repo.

Optional: set `db.local_query` in the profile so `/how-to-verify` and
`/automation-test` can run read-only SQL on the local DB.

## Where to run

- **In a project repo** (e.g. `cd ../projects/woodcraft-tech-be && claude`):
  no need to type the project name, the skills detect it from the current
  directory.
- **In this repo**: `.claude/settings.json` already allows access to
  `../projects`, so one session can work across several repos (FE + BE).

## Layout

```
install.sh / uninstall.sh
shared/               load-project.md: step 0 of every skill;
                      design-check.js: measures a local screen against the design spec
skills/<name>/        SKILL.md + templates of each skill
agents/               alpha-code-reviewer, alpha-db-design-reviewer, alpha-lovable-reader
hooks/                guard-env.mjs: keeps the browser on local/dev while /automation-test runs
projects/<name>/      profile.yaml + notes/<skill>.md (what is specific to each project)
tools/automationflow/ CodingMover: keeps the Mac awake and active (swift run)
```

Skills describe only the **generic process**. Project specifics (paths,
commands, conventions that differ) live in `projects/<name>/`. Code
conventions stay in each project repo's `CLAUDE.md`, because the team shares
that file. See `projects/README.md` for the profile keys and features.

## `/automation-test` safety

- `run-lock.mjs` opens a test session only for `local` (localhost) or `dev`
  (the host declared in the profile). Every other environment is refused.
- While a test session is open, a `PreToolUse` hook blocks every Chrome
  navigation outside that environment. The hook doesn't depend on the model
  behaving. Sessions expire after 8 hours. To remove the lock by hand:
  `rm ~/.config/alpha/test-run.json`.
- SQL runs only `SELECT` in a read-only transaction, and only on local.
  Reset/seed commands run only on local and only after asking.
- Note: when logging in through Chrome, the password still passes through the
  model's context. Use test accounts only.

## Adding a project

Copy `projects/_template/` to `projects/<name>/`, fill in `profile.yaml`, and
write notes only for what differs from the generic skills.

## Relation to the skills in project repos

Project repos keep their original skills (`planning`, `db-design`,
`how-to-verify`, the `code-reviewer` agent…), because they are committed and
the team uses them. This set never edits them. When you change a rule on one
side, consider changing the other.
