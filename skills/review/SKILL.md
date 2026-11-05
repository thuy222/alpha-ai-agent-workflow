---
name: review
description: "Independent, read-only code review of a story, module, branch or diff in an alpha project, for the BE or FE side, by the alpha-code-reviewer agent: checks against the BA doc, the plan's decisions and API contract, Lovable, conventions, shared components and TODOs, and returns numbered findings (R1, R2…); for FE also a property-by-property design diff (DD1…) against the Lovable design spec by the alpha-lovable-reader agent. Use before committing or opening a PR, 'review US02', 'review nhánh này'."
argument-hint: "<project> <module|US id|range> [be|fe] [fix]"
model: sonnet
effort: low
---

# Review

## 0. Load the project

Follow `$ALPHA_HOME/shared/load-project.md` with skill name `review`. Work out
the side(s) and repo(s) from the arguments, the current directory, or the
files in the diff (for `fullstack` changes, review each side separately).

## 1. Run the reviewer

Start the `alpha-code-reviewer` agent (fresh context; don't add your own view
of the code) once per side, in parallel when both, with:

- project name, side, and the absolute path of `$ALPHA_HOME`
- the scope: story id and module, a commit range, or files. Default:
  `git diff <base_branch>...HEAD` plus uncommitted changes, limited to the
  module
- the report language: the profile's `language.chat`

For the FE side, start the `alpha-lovable-reader` agent in `compare` mode in
parallel (same project, `$ALPHA_HOME`, module, the local files in scope and
the report language). It checks the screens against the design spec
`docs/plans/<module>.lovable.md` property by property, writing the spec first
if it is missing.

## 2. Present

Relay the reports as they are (findings table, acceptance checklist, manual
checks still needed, and for FE the **Design diff** table with its `DD`
numbers and the design checks to run in Chrome). Don't drop or soften
findings. If you disagree with one, say so under it with your evidence.

## 3. Fix (only when asked)

Only when the user names findings ("fix R1, R3, DD2") or passed `fix`: apply those
fixes on the current feature branch (never on the base branch), re-run the
profile's checks, and offer a fresh review of the changed files.
