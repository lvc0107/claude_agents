# Subagent 03 — Setup Environment

## ch
Navigate to the correct sub-project inside the `promo_applications` monorepo and activate its virtual environment.

## Input
- `component`: sub-project path relative to `promo_applications/` (e.g. `gateways/evv_link`, `applications/celltrak_admin`, `lambdas/my_lambda`)

## Important Context

`ch` is a shell alias:
```bash
alias ch='cd ~/code/ch/backend/promo_applications'
```
**Do not run `ch` as a command** — it does not work outside an interactive shell session.
Always use the full path: `cd $HOME/code/ch/backend/promo_applications/<type>/<component>`

Project structure:
```
$HOME/code/ch/backend/
├── promo_applications/          ← main monorepo (ch alias lands here)
│   ├── applications/
│   │   ├── celltrak_admin/
│   │   ├── interface_apps/
│   │   └── self_directed/
│   ├── gateways/
│   │   ├── evv_link/
│   │   ├── hq/
│   │   ├── integration/
│   │   ├── interface/
│   │   ├── internal/
│   │   ├── my_tenant/
│   │   ├── otp_gateway/
│   │   └── passthrough/
│   ├── lambdas/
│   ├── libraries/
│   ├── crons/
│   └── platform/
├── promo-applications-config/
├── self-directed-interface/
└── ...
```

---

## Instructions

### 3.1 — Navigate to the sub-project

The ticket's `component` field identifies the sub-folder type and name (e.g. `gateways/evv_link`). Navigate directly:
```bash
cd $HOME/code/ch/backend/promo_applications/<type>/<component>
```

If the component value from the ticket is ambiguous (no type prefix), search for it:
```bash
find $HOME/code/ch/backend/promo_applications -maxdepth 2 -type d -name "<component>"
```

If still unclear, **ask the user before continuing**.

### 3.2 — Special case: `libraries/` or multi-project lambdas

If `component` points to a shared library or a lambda monorepo, it may contain multiple sub-projects:

```bash
ls $HOME/code/ch/backend/promo_applications/<type>/
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
| Folder not found under `promo_applications/` | Run `find $HOME/code/ch/backend/promo_applications -maxdepth 2 -type d` and **ask the user** which folder to use |
| Monorepo and sub-project unclear | List sub-projects and **ask the user** |
| `.venv` missing and `act` fails | Report error — do not continue |
| All OK | Continue to subagent 04 |

## Output
```
✅ Directory: $HOME/code/ch/backend/promo_applications/<type>/<component>
✅ Virtual environment: [.venv (UV) | act (Poetry)]
✅ Python: <version>
```
