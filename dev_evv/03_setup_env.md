# Subagent 03 — Setup Environment

## evv
Navigate to the correct repository inside `$HOME/code/evv/` and activate the project's virtual environment.

## Input
- `component`: project folder name read from the ticket (e.g. `evv_auth_service`)

## Important Context

`evv` is just a shell alias:
```bash
alias evv='cd $HOME/code/evv'
```
**Do not run `evv` as a command** — it does not work outside an interactive shell session.
Always use the full path: `cd $HOME/code/evv/<component>`

Project structure:
```
$HOME/code/evv/
├── evv_auth_service/          ← standard project
├── evv_payments/
├── evv_link_lamdas/           ← AWS Serverless: monorepo containing evv_link* sub-projects
│   ├── evv_link_labbda1/
│   ├── evv_link_lambda2/
│   └── ...
└── .agents/                   ← agent files (not a code project)
```

---

## Instructions

### 3.1 — Navigate to the project
```bash
evv
```

If the component name from the ticket does not include the `evv_` prefix, try both:
```bash
# Attempt 1: exact name from ticket
cd $HOME/code/evv/<component>

# Attempt 2: with evv_ prefix
cd $HOME/code/evv/evv_<component>
```

### 3.2 — Special case: `evv_link_lambda` monorepo

If `component` points to `evv_lib_lambda` or starts with `evv_link`, it may be a sub-project of the monorepo:

```bash
cd $HOME/code/evv/evv_link_lambda
ls -la | grep evv_link
```

If the ticket description does not clarify which sub-project to use, **ask the user before continuing**.

### 3.3 — Verify you are in the right place
```bash
pwd
ls -la
```

### 3.4 — Activate the virtual environment

All projects use Python. Activate in this order:

**Step 1 — Look for `.venv` (managed by UV):**
```bash
ls -la .venv/ 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"
```

**If `.venv` exists:**
```bash
source .venv/bin/activate
which python && python --version
```

**If `.venv` does NOT exist — use `act` (alias that activates a Poetry venv):**
```bash
act
which python && python --version
```

**If `act` also fails:** report to the orchestrator with the current path, directory contents, and the exact error from `act`. Do not continue.

---

## Validations

| Condition | Action |
|-----------|--------|
| Folder not found in `$HOME/code/evv/` | Run `ls $HOME/code/evv/` and **ask the user** which folder to use |
| Monorepo and sub-project unclear | List sub-projects and **ask the user** |
| `.venv` missing and `act` fails | Report error — do not continue |
| All OK | Continue to subagent 04 |

## Output
```
✅ Directory: $HOME/code/evv/<component>
✅ Virtual environment: [.venv (UV) | act (Poetry)]
✅ Python: <version>
```
