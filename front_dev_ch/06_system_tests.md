# Subagent 06 — System Tests (Frontend)

## Role
The CH frontend does not use Behave/BDD system tests. This step validates the full application build and type-check as the integration gate.

## Instructions

Run all checks from inside the app folder (matches what the Jenkinsfile does):

```bash
cd $HOME/code/ch/frontend/web-apps/apps/<component>
```

### 6.1 — Run the full type-check
```bash
npm run check
```

If type errors are found:
- Fix type annotation issues in the implementation
- Report to orchestrator if a code change is required

### 6.2 — Run ESLint
```bash
npm run lint
```

Common lint failures to fix:
- `no-console` violation → remove `console.log`
- `no-restricted-globals` → remove `$inspect`
- Unused imports/variables → remove them
- Missing `curly` braces → add braces

### 6.3 — Run full test suite with coverage
```bash
npm run coverage
```

Coverage must be 100% on all new code (enforced by `vitest.config` thresholds).

## Output
```
✅ Type-check: passed
✅ ESLint: passed
✅ Coverage: 100%
```

If any check fails, report the exact errors and return to step 4.
