---
name: work
description: "Entry point for any task on an alpha project: give a project name plus a request or a document (BA doc, PDF, link, bug report) and it loads the project profile, works out what the request needs (plan, DB design, implement, review, verify guide, browser test run, or a small direct change), and runs the matching alpha skill in the right repo. Use when the user says '/work <project> …' or hands over work for a project without naming the step."
argument-hint: "<project> <request or path/link to a document>"
---

# Work (orchestrator)

## 0. Load the project

Follow `$ALPHA_HOME/shared/load-project.md` with skill name `work`. The rest
of the arguments is the request; any path or link in it is an input document.

## 1. Classify the request

Read the request (and skim any attached document far enough to know what it
is). Pick the route; when two fit, take the earlier step in the flow
`plan → db-design → implement → review → verify → test`.

| The request is… | Route |
| --- | --- |
| New or updated BA user stories, a SOW section, "plan", "lên kế hoạch", a new module or screen | `/plan` (scope from the request or the repo; `fullstack` when both sides change). If it needs new tables, the plan raises the `db-design` question itself. |
| "Design the DB", schema, ERD, new tables, "thiết kế db" | `/db-design` |
| "Code / implement / làm" a story of an agreed plan | `/implement` |
| "Review" a story, branch or diff | `/review` |
| "How to test", "kịch bản test", acceptance scenarios | `/how-to-verify` |
| "Run the tests / chạy test / smoke test" in the browser | `/automation-test` |
| A small, precise change (a bug with clear repro, a copy fix, one field) | Direct change: section 3 |
| Anything else (a question about the code, an estimate) | Answer it directly using the project context |

If the route is still unclear, ask one `AskUserQuestion` with the 2–3 likely
routes, recommended first.

Tell the user the route in one line ("→ plan, fullstack, module purchase-orders")
and continue without waiting unless the step writes to a shared environment.

## 2. Hand over

Invoke the chosen skill with the `Skill` tool, passing
`<project> <the parsed arguments>` (module, scope, stories, document paths).
That skill reloads the project itself; follow it to the end.

When it finishes, suggest the next step of the flow in one line (after plan:
answer the questions, then implement; after implement: review is done inside,
then verify or test).

## 3. Direct change (small requests only)

For a change too small to plan:

1. Confirm the side/repo and restate the change in one sentence.
2. Branch as `/implement` §2 does (`branch_prefix.fix` for a bug).
3. Make the change following the repo's `CLAUDE.md`; reproduce the bug first
   when possible (a failing test with `automated_tests`, or the browser on
   local).
4. Run the profile's checks for that side, then `/review` on the diff.
5. Commit on the branch, with no Claude attribution (see `/implement` §5);
   push/PR only when the user asks.

If the change grows (several stories, new endpoints, schema changes), stop
and switch to `/plan`.
