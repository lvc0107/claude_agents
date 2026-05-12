# 🤖 Orchestrator Agent — EVV DEV Pipeline

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
Example: Using ~/code/.agents implement the full pipeline for the ticket `<ticket_id>`
A shortcut command is dev_evv <ticket_id>

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
- **Component** → folder name inside `$HOME/code/evv/`
- **Acceptance Criteria** → success conditions

Format the branch name as:
```
EVV-<ticket_id>_<Title_With_Underscores_No_Spaces>
```
Example: `EVV-1234_Add_user_authentication_endpoint`

Delegate to: `@agents/01_read_ticket.md`

---

## Step 2 — Git Setup

Delegate to: `@agents/02_git_setup.md`
```bash
git checkout .
git pull --rebase
git checkout -b "EVV-<ticket_id>_<Description>"
```

---

## Step 3 — Environment Setup

Delegate to: `@agents/03_setup_env.md`
```bash
cd $HOME/code/evv/<component>
# activate .venv (UV) or fall back to act (Poetry)
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
- Keep a running state log in `TICKET_STATE.md` at the evv root folder

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
| After 3 consecutive build retries in Step 7 | Run `/compact` — old error logs no longer useful |
| When `/context` shows > 70% | Run `/compact` immediately |

### ⚡ Step 1 — Parallel MCP calls (free optimization)
Call both simultaneously — they are independent:
- `mcp_hchb_get_ado_work_item <ticket_id>`
- `mcp_hchb_coding_standards`

### 🎯 --effort per step (Copilot CLI only)

| Steps | `--effort` level | Reason |
|-------|-----------------|--------|
| Steps 1–3 (ticket, git, env) | `low` | Mechanical steps — no deep reasoning needed |
| Step 4 (implement) | `high` | Complex multi-file reasoning and design decisions |
| Steps 5–6 (unit + system tests) | `medium` | Balance quality and token cost |
| Step 7 (build + retry loop) | `medium` | Iterative error analysis |

```bash
# Start the session with the appropriate effort for the dominant step
gh copilot --effort high --allow-all-tools   # for implementation-heavy sessions
gh copilot --effort medium --allow-all-tools  # for test/build-only sessions
```

### 📁 Build log filtering (Step 7)
Do NOT load the full `build_output.log` into context. Only process filtered lines:
```bash
./build.sh 2>&1 | grep -E "FAILED|ERROR|error:|warnings summary" | tee build_errors.log
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

