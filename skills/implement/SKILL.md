---
name: implement
description: "Write the code for one or more user stories of an agreed alpha plan (docs/plans/<module>.be.md / .fe.md) in the right project repo: checks the plan's open questions, creates a feature branch from the base branch, codes story by story following the repo's CLAUDE.md, ticks the acceptance checklist, runs the project's typecheck/lint/tests, has the alpha-code-reviewer agent review it, and commits on the branch. Use when the user says to start coding, 'code US02', 'làm story', 'implement', after a plan is agreed."
argument-hint: "<project> <module> [be|fe] [US ids | next]"
---

# Implement

Turn an agreed plan into code, one story at a time, in the project's repo.

## 0. Load the project

Follow `$ALPHA_HOME/shared/load-project.md` with skill name `implement`
(`notes/implement.md` if present; also read `notes/plan.md`, whose coding
rules apply here).

Inputs: module, side (`be`/`fe`; for a split layout, default the repo the
session is in; ask if unclear), and the stories (`US02`, `US02-US04`, or
`next` = the first story whose checklist isn't fully ticked, US00 first).

## 1. Gate: is the plan ready?

Read `docs/plans/<module>.<side>.md` (and the other side's plan for its
Decisions and the API contract).

- No plan → stop and offer `/plan`. A small, self-contained change the
  user describes precisely (a bug fix, a one-field addition) may go without a
  plan: say so and confirm once.
- Open questions that touch the chosen stories → list them and ask the user to
  answer or to say "go with the recommendations". Record the answers in the
  plan's Decisions (date, "user") before coding.
- FE story whose endpoints are still `planned` / `missing` in the BE → say so;
  code against the contract with mock data shaped exactly like it, and add a
  Code TODO (feature `code_todos`) where the swap will happen.

## 2. Branch (per repo you will touch)

1. `git -C <repo> status --porcelain`: uncommitted changes that aren't yours →
   stop and ask (never stash, reset or discard someone's work).
2. `git -C <repo> fetch` then branch from the up-to-date base:
   `git -C <repo> switch -c <prefix><module>[-<us>] origin/<base_branch>`
   (`branch_prefix.feature` from the profile, e.g. `feat/purchase-orders`).
   Already on a branch for this module → keep using it.
3. Never commit to the base branch, `main` or `master`.

## 3. Code, story by story

For each story (US00 first when it exists):

1. Re-read the story's section: acceptance checklist, UI spec rows (feature
   `ui_spec`), gaps and their resolutions, tasks, Code TODOs, Lovable mapping.
   Open the Lovable `file:line` references you are porting (the `lovable`
   MCP); port the behaviour and design, never paste a Lovable file whole.
2. Follow the repo's `CLAUDE.md` (layout, naming, components, API layer, i18n,
   commands) and match the surrounding code's style and comment density.
   Teammates' code is additive-only: extra enum values and optional props, no
   renames or reshapes without asking.
3. Shared components first: build each US00 component once in the shared
   location, then use it.
4. BE: entities match `docs/database/<domain>.md`; migrations only with
   feature `migrations`; new permission codes where the project registers
   them; DTO validation for every rule in the checklist.
5. FE: API module and hook typed exactly like the BE contract; empty, loading
   and error states; no native `confirm`/`alert`.
6. Tests (feature `automated_tests`): the unit tests for pure logic and the
   e2e cases the plan lists.
7. Code TODOs (feature `code_todos`): write each `TODO(<module>)` the plan
   lists, and one for anything deferred mid-way (add it to the plan). Delete
   any existing TODO this story resolves (`git grep -n "TODO("` in every
   repo).
8. Tick the story's checklist items in the plan as they land. A story is done
   only when every row is ticked or backed by a Decision.

If something in the plan turns out wrong or impossible, stop and ask: it
becomes a new question in the plan, not a silent change.

## 4. Check

1. Run the profile's `commands.<side>` (`typecheck`, `lint`, and `test` /
   `e2e` with `automated_tests`) from the repo root. Fix what you broke and
   re-run until clean; report anything pre-existing you didn't touch.
2. Run the `/review` flow on the story (the `alpha-code-reviewer` agent,
   fresh context). Fix the `blocker` and `major` findings you agree with;
   bring the rest and any disagreement to the user.
3. Generated files (route trees, icon indexes): include them only when your
   change caused the diff.

## 5. Commit

- Commit on the feature branch, one commit per story (or per US00 component
  group), conventional style in `language.code`:
  `feat(<module>): <US id> <what>`. Stage only the files of this story;
  never commit plans, verify guides, test-run reports, `.env` or credentials.
- Never push or open a PR unless the user asks. When asked, push the branch
  and open the PR against `base_branch`, filling the repo's PR template.

## 6. Hand back

In chat: the stories done, the checklist state, the commands' results, the
review findings and what happened to each, the commits (hash + message),
TODOs added/removed, and what's next. Offer `/how-to-verify` (guide) or
`/automation-test` (run the existing guide) for the module.
