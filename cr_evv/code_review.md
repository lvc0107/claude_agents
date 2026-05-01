# Agent — EVV Code Review

## Role
Given a ticket ID, read the ticket from ADO,
for each component, navigate to the component repo, switch to the ticket branch, and perform a thorough code review of all changes relative to `main`. Produce a structured, actionable report.

> **⚠️ Mandatory:** All ADO interactions (reading tickets, creating tasks, posting comments) **must** use the **HCHB MCP server** tools. Do NOT use the ADO REST API directly or `az` CLI for ADO data unless a specific HCHB MCP tool is unavailable for that operation.

---

## How to invoke

In VS Code MCP chat:
```
Review the following ticket <ticket_id>
A shortcut command is cr_evv <ticket_id>
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
| `component` | Folder name inside `~/code/evv/` |
| `acceptance_criteria` | Acceptance criteria |

**If `component` is empty or missing:**
1. Run `ls $HOME/code/evv/` to list available projects
2. Pause and ask the user which component to use before continuing

---

## Step 2 — Navigate to the component repo and activate the environment

### 2.1 — Navigate to the project
```bash
cd $HOME/code/evv/<component>
```

If the component name does not include the `evv_` prefix, try both:
```bash
cd $HOME/code/evv/<component>
# or
cd $HOME/code/evv/evv_<component>
```

Special case — `evv_link_lambdas` sub-projects are located in this folder:
```bash
cd $HOME/code/evv/evv_link_lambdas
ls -la | grep evv_link
```

### 2.2 — Activate the virtual environment

**Run:**
```bash
act
```

---

## Step 3 — Switch to the ticket branch

### 3.1 — Update main or master branch
```
git checkout main or master
git pull --rebase
```

### 3.2 — Fetch and checkout the branch
```bash
git fetch --all
git checkout EVV-<ticket_id>_<description>
```

| Condition | Action |
|-----------|--------|
| Branch found locally | `git checkout <branch>` |
| Branch not found anywhere | Report error — ask the user for the exact branch name |


Confirm active branch:
```bash
git branch --show-current
```

---

## Step 4 — Apply the code review

### 4.1 — Gather the diff (against main or master)
```bash
# List changed files (main or master)
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

## Step 6 — Post findings to ADO

### 6.1 — Create Code Review ticket

Post this review Creating a Child task for <ticket_id>
Call `create_ado_task`providing

- parent work item id (parentId):  <ticket_id>
- Task title (title): Code review
- Description: leave blank
- Assign to (assignedTo): `$ADO_ASSIGNEE`
- Activity type: Development
- Original estimate: leave blank

Show the URL for the new CR ticket

### 6.2 — Add the report generated as comment

The `update_ado_work_item` tool does not support comments. Use the ADO REST API directly:

```bash
TOKEN=$(az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query accessToken -o tsv 2>/dev/null)

curl -s -X POST \
  "https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT_ID}/_apis/wit/workItems/<cr_ticket_id>/comments?api-version=7.1-preview.3" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": "<html body of the report>"}'
```

- Replace `<cr_ticket_id>` with the task ID returned in step 6.1.
- The report body must be HTML — use `<h2>`, `<p>`, `<table>`, `<ol>`, etc.
- `499b84ac-1321-427f-aa17-267ca6975798` is Azure DevOps' well-known resource ID.

Show the URL for the new CR ticket

---

## Rules

- **Never auto-fix** — this agent only reviews.
- **Always use the HCHB MCP server** for all ADO interactions (read, create, update). Raw REST calls are only permitted as an explicit last resort when no MCP tool covers the required operation.
- If no changes are found (`git diff` is empty), report that the branch has no changes relative to `main` or `master`.
- If the branch has not been pushed yet, review local commits: `git log main..HEAD --oneline` and `git diff main...HEAD`.
