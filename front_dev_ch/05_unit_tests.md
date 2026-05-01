# Subagent 05 — Unit Tests (Frontend / Vitest)

## Role
Write and run Vitest unit tests for the code implemented in the previous step.

**RULE:**
- You MAY modify test files freely
- You MUST NOT modify implementation code directly
- If implementation is wrong → report to orchestrator

## Input
- `implemented_files`: list of files created/modified in step 4
- `component`: sub-app name (e.g. `clearing-house`)

---

## Instructions

### 5.1 — Understand existing test patterns

```bash
cd $HOME/code/ch/frontend/web-apps

# Find tests near the files you implemented
find apps/<component>/src -name "*.test.ts" | head -10

# Read 1–2 existing test files to copy the pattern
```

Vitest globals are enabled — `describe`, `it`, `expect`, `vi` are available without imports.

### 5.2 — Test strategy

Before writing, define:
- Key behaviors to validate per implemented function/component
- Edge cases: empty input, null, missing fields, single item, already-sorted, etc.
- Failure scenarios: API error, invalid data

### 5.3 — Write the tests

**File placement:**
1. Prefer appending to an existing test file if it already tests the same module
2. If the module is new, create `<module-name>.test.ts` alongside the implementation (same folder)
3. **Never** include the ticket ID in a test file name

**Vitest patterns:**
```typescript
// Normalizer test
describe('normalizeMyData', () => {
  it('returns normalized items sorted by name', () => {
    const response = { items: [{ id: '2', name: 'Beta' }, { id: '1', name: 'Alpha' }] };
    expect(normalizeMyData(response)).toEqual({
      items: [{ id: '1', name: 'Alpha' }, { id: '2', name: 'Beta' }],
    });
  });

  it('returns empty items when response is empty', () => {
    expect(normalizeMyData({})).toEqual({ items: [] });
  });

  it('does not mutate the input array', () => {
    const items = [{ id: '2', name: 'Beta' }, { id: '1', name: 'Alpha' }];
    const snapshot = [...items];
    normalizeMyData({ items });
    expect(items).toEqual(snapshot);
  });
});

// Service test (with HTTP mock)
describe('fetchMyData service', () => {
  it('should call http.get with the correct URL', async () => {
    const id = 'some-uuid';
    mockFetchSuccess('get');

    await fetchMyData(id);

    expect(http.get).toHaveBeenCalledWith(`${myBaseUrl}/${id}/endpoint`);
  });

  it('should return safe fallback when the call fails', async () => {
    mockFetchFailure('get');

    const result = await fetchMyData('some-id');

    expect(result).toEqual({ items: [] });
  });
});
```

**Rules:**
- One test per behavior
- Test names: `it('returns X when Y')` — describe behavior not method
- Mock all external dependencies: `vi.fn()`, `vi.mock()`
- Cover: happy path, edge cases (empty, null, missing), error path
- Do NOT add tests just to increase coverage artificially
- Do NOT use `assert_any_call` equivalents — use `toHaveBeenCalledWith` exactly

### 5.4 — Run the tests

Run from inside the app folder (matches what the Jenkinsfile does):

```bash
cd $HOME/code/ch/frontend/web-apps/apps/<component>

# Run only the new tests first
npx vitest run src/path/to/<module>.test.ts --reporter=verbose

# Run the full suite
npm test
```

### 5.5 — Coverage check

Coverage threshold is **100%** (functions, lines, branches, statements — enforced by `vitest.config` `thresholds.autoUpdate`). Any uncovered new public function is a blocker.

```bash
cd $HOME/code/ch/frontend/web-apps/apps/<component>
npm run coverage
```

If coverage drops, add tests for the uncovered paths.

### 5.6 — If tests fail

For each failure:
1. Classify: **TEST_BUG** (wrong expectation/mock) or **CODE_BUG** (implementation wrong)
2. If TEST_BUG → fix the test
3. If CODE_BUG → report to orchestrator to return to step 4

## Output
```
status: SUCCESS | FAILURE

tests_written:
  - apps/<component>/src/routes/(protected)/<domain>/normalizers/myNormalizer.test.ts

tests_passed: true
failures: 0
coverage: 100%

failure_reason: null | "CODE_BUG" | "TEST_BUG"
notes: |
  Short explanation if something failed
```
