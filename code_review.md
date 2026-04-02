# Agent — Code Review

> **Independent agent.** Not part of the dev pipeline. Invoke directly when you want a code review.

## Role
Given a ticket ID, read the ticket from ADO, navigate to the correct component repo, switch to the ticket branch, and perform a thorough code review of all changes relative to `main`. Produce a structured, actionable report.

---

## How to invoke

In VS Code MCP chat:
```
Review the following ticket <ticket_id>
```

---

## Input
- `ticket_id`: ADO ticket number (e.g. `1234`)

---

## Step 1 — Read the ticket from ADO

### 1.1 — Azure login
```bash
az login --allow-no-subscriptions
```
Wait for browser authentication to complete.

| Condition | Action |
|-----------|--------|
| Login succeeds | Continue to step 1.2 |
| Browser doesn't open | Try `az login --use-device-code --allow-no-subscriptions` |
| Login fails | Report error — do not continue |

### 1.2 — Fetch the ticket
```
get_ado_work_item <ticket_id>
```

### 1.3 — Extract the following fields

| Field | Description |
|-------|-------------|
| `title` | Ticket title |
| `description` | Full description of the work done |
| `component` | Folder name inside `$HOME/code/EVV/` |
| `acceptance_criteria` | Acceptance criteria |

**If `component` is empty or missing:**
1. Run `ls $HOME/code/EVV/` to list available projects
2. Pause and ask the user which component to use before continuing

---

## Step 2 — Navigate to the component repo and activate the environment

### 2.1 — Navigate to the project
```bash
cd $HOME/code/EVV/<component>
```

If the component name does not include the `evv_` prefix, try both:
```bash
cd $HOME/code/EVV/<component>
# or
cd $HOME/code/EVV/evv_<component>
```

Special case — `evv_ftp_scheduler` monorepo: if `component` starts with `evv_link`, check sub-projects first:
```bash
cd $HOME/code/EVV/evv_ftp_scheduler
ls -la | grep evv_link
```

### 2.2 — Activate the virtual environment

**Look for `.venv` first (UV-managed):**
```bash
ls -la .venv/ 2>/dev/null && source .venv/bin/activate || echo "NOT_FOUND"
```

**Fallback — Poetry:**
```bash
poetry shell
```

Verify:
```bash
which python && python --version
```

---

## Step 3 — Switch to the ticket branch

### 3.1 — Update main or master branch
```
git checkout main or master
git pull --rebase
```
Rules: only alphanumeric and hyphens after the first `_`. No underscores in the description part.

### 3.2 — Fetch and checkout the branch
```bash
git fetch origin
git checkout EVV-<ticket_id>_<description>
```

| Condition | Action |
|-----------|--------|
| Branch found locally | `git checkout <branch>` |
| Branch only on remote | `git checkout -b <branch> origin/<branch>` |
| Branch not found anywhere | Report error — ask the user for the exact branch name |

### 3.3 — Pull latest
```bash
git pull --rebase
```

Confirm active branch:
```bash
git branch --show-current
```

---

## Step 4 — Apply the code review

### 4.1 — Gather the diff
```bash
# List changed files
git diff --name-only origin/main...HEAD

# Full diff (code only, no binary)
git diff origin/main...HEAD -- '*.py' '*.toml' '*.yaml' '*.yml' '*.json' '*.sh'
```

Also read `pyproject.toml` to confirm tech stack and dependencies.

### 4.2 — Detect the project type

| Indicator | Project type | Key patterns to enforce |
|-----------|-------------|------------------------|
| `flask_restx` in imports | FlaskRestX | Namespace, Resource, api.model |
| `fastapi` in imports | FastAPI | Router, Pydantic models, dependency injection |
| `lambda_handler(event, context)` | AWS Lambda | stateless, no global state, proper boto3 error handling |
| `behave` in test paths | BDD tests | Given/When/Then structure, step reuse |
| `pytest` | Unit tests | fixtures, mocking, coverage |

### 4.3 — Review every changed file

For each finding, record:
- **File** and **line range**
- **Severity**: 🔴 Critical · 🟠 Major · 🟡 Minor · 🔵 Suggestion
- **Category** (below)
- **Explanation** and **recommended fix**

#### 🔒 Security
- [ ] No hardcoded credentials, tokens, or secrets
- [ ] No SQL string interpolation — use parameterized queries / ORM only
- [ ] No shell injection — avoid `subprocess` with `shell=True` and user input
- [ ] Input validated at system boundaries (API endpoints, Lambda handlers)
- [ ] No sensitive data logged (PII, passwords, tokens)
- [ ] Dependencies pinned to specific versions (no unpinned `>=`)

#### 🏗️ Architecture & Design
- [ ] Business logic lives in `services/`, not in `resources/` or `handlers/`
- [ ] No direct DB access from endpoint layer — pass through service layer
- [ ] Functions follow single responsibility principle
- [ ] No circular imports
- [ ] Proper use of dependency injection (Flask `g`, FastAPI `Depends`)

#### ✅ Correctness
- [ ] Exception handling is specific (not bare `except:` or `except Exception:`)
- [ ] All code paths return a value or raise an exception explicitly
- [ ] No mutable default arguments (`def f(x=[])`)
- [ ] No silent failures (empty `except` blocks, swallowed exceptions)
- [ ] Async/await used consistently (no mixing sync/async without care)

#### 🧪 Tests
- [ ] New code has corresponding unit tests
- [ ] Tests cover: happy path, edge cases, expected errors
- [ ] Mocks are used for external dependencies (DB, APIs, S3, etc.)
- [ ] No `assert_any_call` — use `assert_called_once_with` or `assert_has_calls`
- [ ] Test names describe behavior: `test_returns_error_when_user_not_found`

#### 📐 Code Quality
- [ ] No unused imports or variables
- [ ] No duplicated logic that could be extracted
- [ ] No magic numbers/strings — use constants or enums
- [ ] Type hints present for public functions
- [ ] No commented-out code left behind

#### 🚀 Performance
- [ ] No N+1 query patterns (queries inside loops without batching)
- [ ] No unnecessary full-table scans — check for missing `.filter()` clauses
- [ ] Large payloads paginated where appropriate

#### 📋 Acceptance Criteria coverage
- [ ] Every acceptance criterion from the ticket is addressed by the implementation
- [ ] Flag any criterion that appears unimplemented or only partially covered

> If the diff is too large (>500 changed lines), review by file group and summarize each group separately.

---

## Step 5 — Generate the report

Output the report in this format:

```
## Code Review — EVV-<ticket_id>

**Branch:** EVV-<ticket_id>_<description>
**Component:** <component>
**Files reviewed:** N
**Date:** <today>
**Target branch:** main

---

### Ticket summary
<1–2 sentence recap of what the ticket required>

### Implementation summary
<2–3 sentence overview of what the code actually does and overall quality>

---

### Acceptance Criteria coverage

| # | Criterion | Status |
|---|-----------|--------|
| 1 | <criterion> | ✅ Covered / ⚠️ Partial / ❌ Missing |

---

### Findings

#### 🔴 Critical

| # | File | Lines | Category | Issue | Recommended fix |
|---|------|-------|----------|-------|-----------------|
| 1 | src/resources/user.py | 42–45 | Security | SQL built with string concat | Use `db.session.query().filter_by()` |

#### 🟠 Major
_(table same format as above, or "None")_

#### 🟡 Minor
...

#### 🔵 Suggestions
...

---

### Verdict

- [ ] ✅ Approved — no blockers found
- [ ] ⚠️ Approved with comments — minor issues only, can merge after addressing
- [ ] ❌ Changes requested — critical or major issues must be fixed before merge
```

---

## Step 6 — Post findings to ADO (optional)

After showing the report, ask:
```
Post this review as a comment on ticket EVV-<ticket_id>? (yes/no)
```

If yes:
```
update_ado_work_item <ticket_id> --comment "<summary>"
```

---

## Rules

- **Never auto-fix** — this agent only reviews. Implementation fixes belong to `04_implement.md`.
- If no changes are found (`git diff` is empty), report that the branch has no changes relative to `main`.
- If the branch has not been pushed yet, review local commits: `git log main..HEAD --oneline` and `git diff main...HEAD`.
