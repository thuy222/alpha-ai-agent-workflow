# Load the project (step 0 of every workflow skill)

Every workflow skill starts here. It turns "a project name plus a request"
into absolute paths, commands and rules, so the generic skill never guesses a
project fact.

## 1. Find the workflow home

Run `echo "$ALPHA_HOME"`. It is the checkout of the workflow repo (set by
`install.sh`; skills in `~/.claude/skills` are symlinks into it). If it is
empty, stop and tell the user to run `install.sh` from that repo, or add
`"env": { "ALPHA_HOME": "<path to alpha-fullstack>" }` to
`~/.claude/settings.json` and restart Claude Code.

## 2. Pick the project

- From the arguments: the first word, matched against the folder names in
  `$ALPHA_HOME/projects/` (ignore `_template`). Accept an unambiguous prefix
  (`wood` → `woodcraft`).
- With no name: resolve the current directory against every profile's
  `repos.*.path`. If it sits inside one, that is the project (and the repo).
- Still unknown: list the projects and ask once with `AskUserQuestion`.

## 3. Read the profile and the project's own rules

1. `$ALPHA_HOME/projects/<project>/profile.yaml`. Repo paths in it are
   relative to `$ALPHA_HOME`; turn each into an absolute path and check that
   it exists. A missing repo is a stop: tell the user which path is wrong.
2. The `CLAUDE.md` of every repo the task touches, in full, plus the nested
   `CLAUDE.md` of the app or side involved (for a monorepo, e.g.
   `apps/api/CLAUDE.md`). Read them explicitly: when this session runs from
   another directory, Claude Code does not load them for you. The project's
   `CLAUDE.md` wins over these skills on conventions (layout, naming, commands,
   git), because the team shares it.
3. `$ALPHA_HOME/projects/<project>/notes/<skill>.md` if it exists (`plan.md`,
   `db-design.md`, `implement.md`, `review.md`, `how-to-verify.md`, `automation-test.md`). It is
   the project addendum for the running skill: concrete paths, extra sections,
   and rules that replace the generic wording where they conflict.
4. `features` in the profile switch optional parts of the skills on or off
   (see `$ALPHA_HOME/projects/README.md`). A feature the profile doesn't list
   is off.

## 4. Resolve the paths the skill uses

- **Code roots per side**: `be` and `fe` from `repos` (a whole repo in a
  `split` layout; a folder such as `apps/api` inside the one repo in a
  `monorepo`).
- **Docs root**: `docs.repo` + `docs.*`. In a `split` layout the docs of both
  sides live in one repo; every `docs/…` path in the skills means that repo's
  docs folder, also when working on the other side.
- **Plans**: `docs.plans` is git-ignored in every project. Plans are local
  working files: never commit them, never link to them from committed files.

Work with absolute paths (or `git -C <repo>`) for everything in a project
repo. Never `cd` into a repo and assume later commands still run there.

## 5. Language

`language.chat` is what you speak with the user, `language.docs` what local
plans and guides are written in, `language.code` what code, comments,
commits, PRs and committed docs are written in. Keep UI labels exactly as the
app shows them and identifiers in English whatever the doc language.

## 6. Say what you resolved

Before the real work, tell the user in one short line: project, repo(s) and
side, base branch, and the notes file you loaded (or "no notes").
