# Project profiles

One folder per project. The workflow skills read these through
`$ALPHA_HOME/shared/load-project.md`.

```
projects/<name>/
  profile.yaml      facts the skills route on (repos, docs, commands, envs)
  notes/<skill>.md  project addendum for one skill: paths, extra sections,
                    rules that replace the generic wording where they conflict
```

Coding conventions stay in each repo's `CLAUDE.md` (the team shares it).
A profile only holds what the workflow needs to find and run things.
Passwords never go here: see `skills/automation-test/SKILL.md` for the credentials file.

## `profile.yaml` keys

| Key | Meaning |
| --- | --- |
| `name`, `title` | Folder name used on the command line; human name |
| `layout` | `monorepo` (one repo, `be`/`fe` are folders) or `split` (one repo per side) |
| `repos.<id>.path` | Repo path relative to `$ALPHA_HOME` |
| `repos.<id>.sides` | Monorepo only: side → folder inside the repo (`be: apps/api`) |
| `repos.<id>.side` | Split only: which side this repo is (`be` or `fe`) |
| `docs.repo` | Repo id that holds `docs/` for both sides |
| `docs.plans`, `docs.user_stories`, `docs.database` | Paths inside the docs repo |
| `lovable_project` | Lovable project id (read through the `lovable` MCP) |
| `git.base_branch` | Branch new work starts from and PRs target |
| `git.branch_prefix` | Map of work type → prefix (`feat/`, `fix/`, `chore/`) |
| `commands.<side>.*` | `typecheck`, `lint`, `test`, `e2e`: **read-only** commands (never one that runs `--fix`) |
| `commands.dev` | How to start the apps locally (the skills ask before starting servers) |
| `environments` | `local:` and `dev:` base URLs, **one per line, `key: url`**. `/automation-test` refuses any other key, and its guard script parses this block line by line |
| `db.local_query` | Optional shell prefix that runs one SQL statement against the **local** DB, e.g. `psql postgres://u:p@localhost:5432/app -c`. Used read-only by `/how-to-verify` and `/automation-test` |
| `language` | `chat`, `docs`, `code` (`vi` / `en`) |
| `features` | Optional parts of the skills, below |

## Features

| Feature | Effect |
| --- | --- |
| `ui_spec` | FE plans carry a **UI spec (Lovable)** table with `UI-L` checklist rows; review and verify check the screen against it |
| `ba_delta` | When a BA doc changes after code was built, plans get a **BA delta** section and untick affected items |
| `code_todos` | Plans list **Code TODOs** per story; implement writes `TODO(<module>)` comments; review checks them |
| `fe_test_scenarios` | FE plans end with a manual **Test scenarios** table |
| `automated_tests` | The project has unit/e2e tests: plans list them, implement writes them, review runs them |
| `mock_phase` | Screens can run on mock stores before the API exists (`mock` vs `api` phase) |
| `db_questions_in_be_plan` | DB open questions/decisions live in the module's BE plan (section "DB design") instead of `docs/plans/database.md` + the domain doc |
| `migrations` | Schema changes ship as migrations (off = `synchronize` on dev, entities only) |

## New project

Copy `_template/`, fill `profile.yaml`, and add notes only for what differs
from the generic skill.
