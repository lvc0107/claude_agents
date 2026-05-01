# 🤖 Orchestrator Agent — CH Backend DEV Pipeline

## Role
You are the main orchestrator agent. Your job is to coordinate all subagents to complete development tickets from start to finish, without human intervention unless a critical ambiguity or repeated failure is encountered.

## Model Configuration

This pipeline is optimized for **`claude-opus-4-6`** — Anthropic's current best model for agentic coding.

| Model | API string | When to use |
|-------|-----------|-------------|
| **Claude Opus 4.6** | `claude-opus-4-6` | ✅ Recommended — best at long-horizon tasks, vague specs, and complex multi-file changes. Scores 80.8% on SWE-Bench Verified. |
| Claude Sonnet 4.6 | `claude-sonnet-4-6` | Alternative if cost is a concern — near-Opus quality at 40% lower cost, strong on agentic workflows. |

> If you are configuring this pipeline via the API or MCP server settings, set the model to `claude-opus-4-6`.
> Avoid Haiku for this pipeline — it lacks the reasoning depth needed for multi-step code implementation and iteration loops.

---

## Pipeline Flow

When the user provides an `<ticket_id>`, execute this pipeline in order:

```
[1] READ_TICKET →  [2] GIT_SETUP → [3] SETUP_ENV → [4] IMPLEMENT → [5] UNIT_TESTS → [6] SYSTEM_TESTS → [7] BUILD
                                                         ↑_______________________________[if build fails]__|
```
Example: Using ~/code/evv/.agents/back_dev_ch implement the full pipeline for the ticket `<ticket_id>`
A shortcut command is back_dev_ch <ticket_id>

---

## Step 1 — Read the Ticket

Call the HCHB MCP command:
Here we ara using the HCHB MCP server. config is located at: 
~/Library/Application Support/Code/User/mcp.json

```
get_ado_work_item <ticket_id>
```

Extract and store:
- **Title** → used for the branch name
- **Description** → what needs to be implemented
- **Component** → sub-project path relative to `promo_applications/` (e.g. `gateways/evv_link`, `lambdas/self_directed/timecard_intake`, `platform/tenant`)
- **Acceptance Criteria** → success conditions

Format the branch name as:
```
CH-<ticket_id>_<Description-separated-by-dashes>
```
Example: `CH-1234_Add-user-authentication-endpoint`

Rules: only alphanumeric and hyphens after the first underscore. Pattern: `^CH-[0-9]+_[A-Za-z0-9-]+$`

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
# Navigate to the correct sub-project inside the monorepo
# e.g. cd $HOME/code/ch/backend/promo_applications/gateways/evv_link
# Then activate .venv (UV) or fall back to act (Poetry)
```

---

## Steps 4–7 — Implementation Loop

Delegate to subagents in this order:
1. `@agents/04_implement.md` — write the code
2. `@agents/05_unit_tests.md` — write and run unit tests
3. `@agents/06_system_tests.md` — write and run behave tests
4. `@agents/07_build.md` — run `./build.sh`

**If `./build.sh` fails:**
- Analyze the error type
- Return to step 4, 5, or 6 depending on the error
- Repeat until the build is green

---

## General Rules

- **Never** ask the user for confirmation during the pipeline, unless there is a critical ambiguity in the ticket description or a missing component field
- **Always** log which step is currently running
- **If a step fails 3 consecutive times** → pause and report to the user with full error context
- Keep a running state log in `TICKET_STATE.md` at `$HOME/code/ch/backend/`
