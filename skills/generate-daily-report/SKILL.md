---
name: generate-daily-report
description: "Write the planned daily report (a forward schedule, day by day) for a module of an alpha project: schedules the given number of working days story by story, each user story finished end to end (BE, FE, API integration) before the next one starts, follows the plans' PR split and the BA doc's exact user story IDs and titles, prints it in Markdown and copies it to the macOS clipboard as rich text for Slack. Use when the user asks for a daily report, a planned or expected report, or a day-by-day schedule to paste into Slack."
argument-hint: "<project> <module> <days, e.g. '9 days' or '9 days: 3 FE, 5 BE, 1 integration'> [start=<date>] [ba=<path>]"
model: sonnet
effort: low
---

# Generate daily report

A planned, day-by-day report the user pastes into Slack. It writes no project
files: only `report.md` and `report.html` in the scratchpad.

## 0. Load the project

Follow `$ALPHA_HOME/shared/load-project.md` with skill name
`generate-daily-report` (`notes/generate-daily-report.md` if present).

Inputs, from the arguments or the conversation:

- **Module** (kebab-case key, e.g. `work-orders`).
- **Days**: total working days (e.g. "9 days"). Missing → ask once with
  `AskUserQuestion`.
- **Split** (optional): how many of those days go to FE, BE and API
  integration overall (e.g. "3 FE, 5 BE, 1 integration"). It sets the share
  of each side **inside** every story, not the order of the schedule.
- **Order inside a story** (optional): default BE → FE → integration, so the
  FE is wired to the real API instead of mock data. Use the order the user
  gives (e.g. FE first on a UI-first module with feature `mock_phase`).
- **Start date**: default today, and today is day 1.
- **BA doc**: default `docs/user-stories/<module>.md` in the docs root.

## 1. Dates

Count working days only, skipping Saturday and Sunday. If the start date is a
Saturday or Sunday, start on the next Monday. Get today's date and weekday
from `date`, never from memory. Format each day as `Ddd, Mon D`
(`Tue, Oct 27`).

## 2. Read the sources

1. The BA doc: take every user story's ID and title **exactly** as written,
   including dashes such as "—" (`US04: Unit Record — Details`). Never invent a
   story the BA doc doesn't have (no `US00`). Shared work (mock data, shared
   components, DB design, permissions) is written as a plain description.
2. The plans, if they exist (`docs/plans/<module>.fe.md` and `.be.md`): split
   the work along their **PR split** (order and grouping of stories per PR or
   commit). Note stories a plan assigns to another module (e.g. a portal
   story) and say how you handled them in the closing lines.
3. No plan → follow the BA doc's story order and keep related small stories
   on the same day.

## 3. Build the schedule

- **Story by story.** Each story is finished end to end (its BE, its FE,
  then its API integration and check) before the next story starts. Never
  build all the FE and then all the BE.
- **Shared groundwork first**, as plain descriptions: DB design, shared
  components, permissions, anything every story needs (the plans' US00 or
  first PR). Keep it to what the first stories need; groundwork only a
  later story needs goes just before that story.
- **Story order**: the plans' PR split, else the BA doc's order.
- **Sizing**: weigh each story by its plans (tasks, checklist items,
  endpoints, screens per side; the BA doc when there is no plan) and share
  the total days in proportion, heavier stories getting more. With a split,
  each side's share inside the stories follows it, so the totals per side
  roughly match what the user gave. A story may span several days, and a
  day may hold the end of one story and the start of the next.
- Write a story's parts as separate items in their order, so each day shows
  how far the story got: `US02: … - BE`, then `US02: … - FE`, then
  `US02: … - FE + BE (API integration)`. A small story done in one day may be
  one item `- FE + BE`.
- The last day keeps room for the module-wide wrap-up (regression check,
  review fixes, PRs) unless the user says otherwise.
- Every item ends with ` - FE`, ` - BE` or ` - FE + BE`. Extra detail goes in
  parentheses after the tag: `US04: Work Order Detail — Customer & Equipment
  Tabs - BE (hours/mileage readings)`.
- Module and table names go in backticks (`` `Work Order` ``,
  `` `unit_files` ``).
- **In progress** of a day is exactly the **first** item of the next day's
  **Completed**. The last day's In progress is the wrap-up that follows
  (review fixes and PRs, or whatever the user names).
- Written in English whatever `language.chat` is.

Format per day:

```
**<Ddd, Mon D>**
**Completed:**
- <item>
**In progress:**
- <item worked on next>
```

## 4. Output

1. Write the report from **one** data structure to both files in a new
   scratchpad folder, so they never drift apart:
   - `report.md`: the Markdown above, a blank line between days.
   - `report.html`: starts with `<meta charset="utf-8">`; `<p><b>…</b></p>`
     for each day and each label, `<ul><li>…</li></ul>` for the items,
     backticks become `<code>…</code>`, text HTML-escaped.
2. Copy it as rich text:
   `$ALPHA_HOME/skills/generate-daily-report/copy-html.sh <abs path>/report.html`
   (macOS only; elsewhere say the clipboard step was skipped and give the
   file path).
3. Print the whole report in the chat in Markdown, exactly as in `report.md`.
4. After it, 1–2 lines in `language.chat`: copied to the clipboard (or not),
   the date range, the days each story takes, and which days risk slipping and why (heavy days,
   dependencies on other modules or unfinished endpoints).

## 5. Changes

When the user asks for a change, edit the data, regenerate both files, print
the new report in full and copy it again.
