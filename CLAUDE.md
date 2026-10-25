# alpha-fullstack

This repo is a set of personal Claude Code skills and agents (see
`README.md`), installed by `install.sh` as symlinks into `~/.claude/skills`
and `~/.claude/agents`. Editing it means editing skills, agents, hooks and
project profiles, not application code.

- Skills hold the **generic process** only. Anything project-specific (paths,
  commands, conventions that differ) goes into `projects/<name>/profile.yaml`
  or `projects/<name>/notes/<skill>.md`. A new optional behaviour that only
  some projects use becomes a `features` flag, documented in
  `projects/README.md`.
- Every skill starts with `shared/load-project.md`. Keep that contract
  stable; if you change it, check every skill that relies on it.
- `skills/how-to-verify/verify-template.md` defines the structure `skills/automation-test`
  parses. Change both together.
- Skills are invoked by folder name (`/plan`, `/work`…); agents keep the
  `alpha-` prefix so project agents with the same base name don't shadow
  them. Adding a skill or agent needs a re-run of `./install.sh`; edits to
  existing files apply from the next session.
- Skills, agents and templates are written in English; chat with the user in
  Vietnamese.
- Never put credentials in this repo. Test accounts live in
  `~/.config/alpha/credentials/<project>.yaml`.
- The project repos under `../projects/` keep their own committed skills; this
  repo never edits them.
