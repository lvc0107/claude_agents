# Subagent 07 — Build & Iterate (Frontend)

## Role
Run the production build and coordinate the correction loop until the build is green.

## Input
- `component`: sub-app name (e.g. `clearing-house`)
- `attempt_number`: current attempt number
- `max_attempts`: 10 (default)

---

## Instructions

### 7.1 — Run the build
```bash
cd $HOME/code/ch/frontend/web-apps
npm run build --workspace=apps/<component>
```

### 7.2 — Analyze failures

| Error type | Return to |
|-----------|-----------|
| TypeScript compile error | Step 4 (implement) |
| ESLint error | Step 4 (implement) |
| Test coverage below 100% | Step 5 (unit tests) |
| Missing import / module not found | Step 4 (implement) |
| Svelte component error | Step 4 (implement) |

### 7.3 — Iterate

- Fix only the specific error — do not refactor unrelated code
- Re-run the build after each fix
- If the same error repeats 3 times → pause and report to the user with full error context

### 7.4 — On success

```bash
# Verify the full test suite still passes
npm run test --workspace=apps/<component>
```

Update `TICKET_STATE.md` at `$HOME/code/ch/`:
```
## Build Attempts
- Attempt <N>: SUCCESS
```

## Output
```
✅ Build: passed
✅ Tests: all passing
✅ Active branch: EVV-<ticket_id>_<description>
```
