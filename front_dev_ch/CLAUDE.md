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
 ECH- <ticket_id>_<Description-separated-by-dashes>
```
Example: ` ECH- 671823_Limit-Service-Locations-by-Member-Address`

Rules: only alphanumeric and hyphens after the first underscore. Pattern: `^ ECH- [0-9]+_[A-Za-z0-9-]+$`

Write a `TICKET_STATE.md` file at `$HOME/code/ch/frontend/web-apps`:
```markdown
# Ticket State

## Info
- **ticket_id**: <ticket_id>
- **Branch**:  ECH- <ticket_id>_<description>
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
git stash save "WIP before  ECH- <ticket_id>"
git checkout main
git pull --rebase
git checkout -b " ECH- <ticket_id>_<Description-with-dashes>"
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

---

## Context & Token Management

Long pipelines accumulate context. Apply these rules to avoid hitting the model's window limit.

### 📊 Monitoring — where to see token consumption

**In the Copilot CLI (recommended for this pipeline):**
```bash
> /context     # Visual bar of current context window usage
               # Example: ████████████░░░░ 60% (72,000 / 120,000 tokens)
> /usage       # Full session stats: total tokens, LLM calls, tool executions, estimated cost
> /chronicle   # Detailed turn-by-turn history with tokens per turn
```

**In VS Code (if running from IDE Agent Mode):**
- Open Copilot Chat panel (`Ctrl+Shift+I` / `Cmd+Shift+I`)
- Look at the **bottom bar** of the chat panel — shows `Tokens: 45,234 / 128,000`
- A progress bar fills as the session grows; once it turns yellow/red, compact the context

**In PyCharm:**
- `Settings → Tools → GitHub Copilot → Usage Statistics`
- Shows request count and session time — less granular than VS Code
- For per-token data open the integrated terminal and run `gh copilot` with `/context`

### ⚠️ Alert thresholds

| Context usage | Action |
|---|---|
| < 50% | ✅ Normal — continue |
| 50–70% | 🟡 Caution — consider `/compact` before starting a heavy step |
| > 70% | 🔴 Run `/compact` immediately before continuing |
| Session total > 100k tokens | Split into a new session — start from `TICKET_STATE.md` |

### 🗜️ When to run /compact

| Point in pipeline | Action |
|---|---|
| After Step 4 completes (before Step 5) | Run `/compact` — implementation exploration history no longer needed |
| After 3 consecutive build retries in Step 6 | Run `/compact` — old build error logs no longer useful |
| When `/context` shows > 70% | Run `/compact` immediately |

### ⚡ Step 1 — Parallel MCP calls (free optimization)
Call both simultaneously — they are independent:
- `mcp_hchb_get_ado_work_item <ticket_id>`
- `mcp_hchb_coding_standards`

### 🎯 --effort per step (Copilot CLI only)

| Steps | `--effort` level | Reason |
|-------|-----------------|--------|
| Steps 1–3 (ticket, git, env) | `low` | Mechanical steps — no deep reasoning needed |
| Step 4 (implement) | `high` | Complex multi-file component/store/service changes |
| Step 5 (unit tests) | `medium` | Balance quality and token cost |
| Step 6 (build + retry loop) | `medium` | Iterative TypeScript/Svelte error analysis |

```bash
# Start the session with the appropriate effort for the dominant step
gh copilot --effort high --allow-all-tools   # for implementation-heavy sessions
gh copilot --effort medium --allow-all-tools  # for test/build-only sessions
```

### 📁 Build log filtering (Step 6)
Do NOT load the full `npm run build` output into context. Only process error lines:
```bash
npm run build 2>&1 | grep -E "error TS|ERROR|Error:|✗" | tee build_errors.log
echo "EXIT_CODE: $?"
```
Read only `build_errors.log` — not the full log.

### 📈 Persistent monitoring (optional — recommended for long sessions)
Enable OTel to log tokens automatically — add to `~/.zshrc`:
```bash
export COPILOT_OTEL_FILE_EXPORTER_PATH=~/.copilot/logs/otel.jsonl
```
Run `~/.agents/token_summary.sh` at end of day for a usage report.
See `COPILOT_HCHB_REPORT.md §16` for full setup and alert script.

