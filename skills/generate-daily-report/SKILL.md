---
name: generate-daily-report
description: "Write the planned daily report (a forward schedule, day by day) for a module of an alpha project: splits the given number of working days between FE, BE and API integration, follows the plans' PR split and the BA doc's exact user story IDs and titles, prints it in Markdown and copies it to the macOS clipboard as rich text for Slack. Use when the user asks for a daily report, a planned or expected report, or a day-by-day schedule to paste into Slack."
argument-hint: "<project> <module> <days and split, e.g. '9 days: 3 FE, 5 BE, 1 integration'> [start=<date>] [ba=<path>]"
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
- **Days and split**: total working days and how many go to FE, BE and API
  integration, in that order unless the user says otherwise (e.g. "9 days, 3
  FE, 5 BE, 1 integration"). Missing → ask once with `AskUserQuestion`.
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

- Days go FE first, then BE, then integration, unless the user gives another
  order. Spread the stories evenly over each phase's days, heavier stories
  alone or with one small one.
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
   the date range, and which days risk slipping and why (heavy days,
   dependencies on other modules or unfinished endpoints).

## 5. Changes

When the user asks for a change, edit the data, regenerate both files, print
the new report in full and copy it again.
