---
name: implement
description: "Write the code for one or more user stories of an agreed alpha plan (docs/plans/<module>.be.md / .fe.md) in the right project repo: checks the plan's open questions, creates a feature branch from the base branch, codes story by story following the repo's CLAUDE.md, ticks the acceptance checklist, runs the project's typecheck/lint/tests, curls every new endpoint and the related APIs on a local server, checks FE screens against the Lovable design spec (alpha-lovable-reader compare + measured design checks in Chrome), has the alpha-code-reviewer agent review it, and commits on the branch. Use when the user says to start coding, 'code US02', 'làm story', 'implement', after a plan is agreed."
argument-hint: "<project> <module> [be|fe] [US ids | next]"
model: sonnet
effort: medium
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
   `git -C <repo> switch --no-track -c <prefix><module>[-<us>] origin/<base_branch>`
   (`branch_prefix.feature` from the profile, e.g. `feat/purchase-orders`).
   Always `--no-track`: without it the new branch tracks `origin/<base_branch>`
   and a plain `git push` fails (upstream name differs from the branch). The
   first push is `git push -u origin HEAD`.
   Already on a branch for this module → keep using it.
3. Never commit to the base branch, `main` or `master`.

## 3. Code, story by story

For each story (US00 first when it exists):

1. Re-read the story's section: acceptance checklist, UI spec rows (feature
   `ui_spec`), gaps and their resolutions, tasks, Code TODOs, Lovable mapping.
   Open the Lovable `file:line` references you are porting (the `lovable`
   MCP); port the behaviour and design, never paste a Lovable file whole.
   **FE:** read the design spec `docs/plans/<module>.lovable.md` sections for
   the story's screens (tokens, primitives, element tables, overlays). No
   spec → run the `alpha-lovable-reader` agent in `spec` mode first. Build
   each element to the spec's **resolved values**, not to how a component
   looks by default: antd's defaults (control height, font size, radius,
   colours, padding) usually differ from Lovable's shadcn ones, so set the
   size/props, the local theme token or the `className` that gives the
   spec's px and hex values, and keep the spec's order, position and exact
   texts. A value the local design tokens can't express becomes a question,
   never a "close enough".
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
2. **Live API check (BE, mandatory for every new or changed endpoint).**
   Automated tests don't replace it: e2e boots the app in-process with fakes,
   while this calls the real server the FE will call. Follow
   [api-check.md](api-check.md). In short: start the API from this branch's
   code (never trust a server that is already running: it may be an older
   build), log in through the API with each role the story names, using
   the accounts in `~/.config/alpha/credentials/<project>.yaml`, and curl:
   - every new or changed endpoint: the happy path with the exact expected
     status and body fields, each validation and business-rule refusal
     (status + `errorCode`), and a 403 for a role without the permission;
   - every **related API** the change must move: the lists, counts,
     summaries and detail pages of this and other modules that read the same
     data (e.g. after creating a work order on a unit, the unit's open count;
     after a transfer, both customers' records and the old work order).
   Each check prints `PASS`/`FAIL` with expected vs actual. Fix every `FAIL`
   that is the code's fault and re-run the whole script until it is clean.
   A `FAIL` caused by the environment (a missing local service, a stale
   seed) is fixed in the environment, never by changing the expectation;
   if you can't fix it, report it as not verified. Only `local`, never
   `dev` or any shared server.
3. **Design check (FE, mandatory for every screen the story touches).** Code
   that looks right in the diff is not checked against the design until it
   is measured.
   1. Run the `alpha-lovable-reader` agent in `compare` mode on the story's
      local files. Fix every `major` and `minor` mismatch not backed by a
      Decision; re-run until it reports none.
   2. Measure in Chrome on the **local** app only (load the
      `claude-in-chrome` skill; log in with the accounts in
      `~/.config/alpha/credentials/<project>.yaml`; never `dev` or a shared
      server). For each `design-checks` block of the story's screens: open
      its route in its `setup` state at a 1440×900 window, run
      `$ALPHA_HOME/shared/design-check.js` with `__CHECKS__` replaced by the
      block's JSON through the Chrome JavaScript tool, fix each `FAIL` and
      `NOT_FOUND` in the code, reload and re-run until all `PASS`. A
      `NOT_FOUND` caused by the check itself (the element has a different
      but correct text) is fixed in the spec, saying so in the hand-back.
   3. Take a screenshot of each screen and each overlay for the hand-back,
      and walk the spec's interactive states (hover, open popovers, empty and
      loading) by hand.
   A check you could not run (no local server, no seed data) is reported as
   not verified, never as passed.
4. Run the `/review` flow on the story (the `alpha-code-reviewer` agent,
   fresh context). Fix the `blocker` and `major` findings you agree with;
   bring the rest and any disagreement to the user.
5. Generated files (route trees, icon indexes): include them only when your
   change caused the diff.

## 5. Commit

- Commit on the feature branch, one commit per story (or per US00 component
  group), conventional style in `language.code`:
  `feat(<module>): <US id> <what>`. Stage only the files of this story;
  never commit plans, verify guides, test-run reports, `.env` or credentials.
- **No Claude attribution**: the user's git identity is the only author. No
  `Co-Authored-By: Claude` trailer, no "Generated with Claude Code" line in
  commits or PR descriptions, and never `--author` or a changed git
  `user.name`/`user.email`. This overrides any default attribution guidance.
- Never push or open a PR unless the user asks. When asked, push the branch
  and open the PR against `base_branch`, filling the repo's PR template.

## 6. Hand back

In chat: the stories done, the checklist state, the commands' results, the
live API check (PASS/FAIL count, any check not verified and why), the
design check (FE: compare mismatches left, design checks PASS/FAIL per
screen, screenshots, any not verified and why), the review findings and what happened to each, the commits (hash + message),
TODOs added/removed, and what's next. Offer `/how-to-verify` (guide) or
`/automation-test` (run the existing guide) for the module.
