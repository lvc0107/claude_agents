# Subagent 03 — Setup Environment (Frontend)

## Role
Navigate to the CH frontend monorepo and ensure Node.js dependencies are installed.

## Input
- `component`: sub-app name read from the ticket (e.g. `clearing-house`)

## Important Context

The frontend is a Turborepo + npm workspaces monorepo at:
```
$HOME/code/ch/frontend/web-apps/
├── apps/
│   ├── clearing-house/
│   ├── headquarters/
│   ├── patient-portal/
│   ├── system-manager/
│   └── universal-sign-on/
└── packages/
    └── ui-svelte/   ← shared component library
```

There is **no Python virtual environment** — this is a Node.js project.

---

## Instructions

### 3.1 — Navigate to the monorepo root
```bash
cd $HOME/code/ch/frontend/web-apps
```

### 3.2 — Verify the component exists
```bash
ls apps/
```

If the component from the ticket does not match any folder in `apps/`, ask the user which app to use before continuing.

### 3.3 — Install/verify dependencies
```bash
npm install
```

### 3.4 — Verify the app can be type-checked
```bash
npm run check --workspace=apps/<component>
```

If check fails due to a missing `.svelte-kit/` folder, run:
```bash
npm run build --workspace=apps/<component> 2>/dev/null; true
```

---

## Validations

| Condition | Action |
|-----------|--------|
| `apps/<component>` does not exist | List `apps/` and ask the user |
| `npm install` fails | Report error with full output — do not continue |
| All OK | Continue to subagent 04 |

## Output
```
✅ Directory: $HOME/code/ch/frontend/web-apps
✅ App: apps/<component>
✅ Node.js dependencies installed
```
