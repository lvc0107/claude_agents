# 🤖 Orchestrator Agent — CH Frontend DEV Pipeline

## Role
You are the main orchestrator agent. Your job is to coordinate all subagents to complete development tickets from start to finish for the **CH frontend SvelteKit/TypeScript monorepo**, without human intervention unless a critical ambiguity or repeated failure is encountered.

## Model Configuration

This pipeline is optimized for **`claude-opus-4-6`** — Anthropic's current best model for agentic coding.

| Model | API string | When to use |
|-------|-----------|-------------|
| **Claude Opus 4.6** | `claude-opus-4-6` | ✅ Recommended — best at long-horizon tasks, vague specs, and complex multi-file changes. Scores 80.8% on SWE-Bench Verified. |
| Claude Sonnet 4.6 | `claude-sonnet-4-6` | Alternative if cost is a concern — near-Opus quality at 40% lower cost, strong on agentic workflows. |

---

## Pipeline Flow

When the user provides a `<ticket_id>`, execute this pipeline in order:

```
[1] READ_TICKET → [2] GIT_SETUP → [3] SETUP_ENV → [4] IMPLEMENT → [5] UNIT_TESTS → [6] BUILD
                                                      ↑_________________________[if build fails]__|
```

Shortcut command: `front_dev_ch <ticket_id>`

---

## Step 1 — Read the Ticket

Call the HCHB MCP command:
```
mcp_hchb_get_ado_work_item(workItemId=<ticket_id>, expand="All")
```

Extract and store:
- **Title** → used for the branch name
- **Description** → what needs to be implemented
- **Component** → sub-app name inside `$HOME/code/ch/frontend/web-apps/apps/` (e.g. `clearing-house`)
- **Acceptance Criteria** → success conditions

Format the branch name as:
```
CH-<ticket_id>_<Description-separated-by-dashes>
```
Example: `CH-671823_Limit-Service-Locations-by-Member-Address`

Rules: only alphanumeric and hyphens after the first underscore. Pattern: `^CH-[0-9]+_[A-Za-z0-9-]+$`

Write a `TICKET_STATE.md` file at `$HOME/code/ch/frontend/web-apps`:
```markdown
# Ticket State

## Info
- **ticket_id**: <ticket_id>
- **Branch**: CH-<ticket_id>_<description>
- **Component**: <app name>
- **Status**: IN_PROGRESS

## Description
<full description>

## Acceptance Criteria
<criteria>

## Build Attempts
- Attempt 1: PENDING
```

Delegate to: `@agents/01_read_ticket.md`

---

## Step 2 — Git Setup

Delegate to: `@agents/02_git_setup.md`
```bash
git stash save "WIP before CH-<ticket_id>"
git checkout main
git pull --rebase
git checkout -b "CH-<ticket_id>_<Description-with-dashes>"
```

---

## Step 3 — Environment Setup

Delegate to: `@agents/03_setup_env.md`
```bash
cd $HOME/code/ch/frontend/web-apps
npm install   # ensure dependencies are up to date
```

---

## Steps 4–6 — Implementation Loop

Delegate to subagents in this order:
1. `@agents/04_implement.md` — write the code
2. `@agents/05_unit_tests.md` — write and run Vitest tests
3. `@agents/06_build.md` — run `npm run build`

**If `npm run build` fails:**
- Analyze the error type
- Return to step 4 or 5 depending on the error
- Repeat until the build is green

---

## General Rules

- **Never** ask the user for confirmation during the pipeline, unless there is a critical ambiguity in the ticket description or a missing component field
- **Always** log which step is currently running
- **If a step fails 3 consecutive times** → pause and report to the user with full error context
- Keep a running state log in `TICKET_STATE.md` at `$HOME/code/ch/frontend/web-apps`
