# Subagent 05 — Unit Tests

## Role
Write and run unit tests for the code implemented in the previous step.

**Rules:**
- You MAY modify test files freely
- You MUST NOT modify implementation code — report CODE_BUG to the orchestrator instead

## Input
- `implemented_files`: list of files created/modified in step 4
- `component`: sub-project path (determines test layout)

---

## Instructions

### 5.1 — Understand the test layout

All projects use **pytest** with **pytest-mock** (`mocker` fixture). Tests live under `tests/` and mirror the source package structure:

```
tests/
└── <package_name>/        ← mirrors src/<package_name>/
    ├── __init__.py
    ├── test_<module>.py
    ├── api/
    │   └── test_<resource>.py
    └── services/
        └── test_<service>.py
```

Read 1–2 existing test files before writing to mirror the exact style:
```bash
find tests/ -name "test_*.py" | head -5
```

### 5.2 — Write the tests

**Before writing, define:**
- Key behaviors to validate
- Edge cases
- Failure scenarios

**File placement:**
1. If an existing test file already covers the module/class → **append** to it
2. If the code is genuinely new → create `tests/<package>/<module>/test_<name>.py` — **never include the ticket ID in the filename**

**Mocking:**
- Use `mocker.patch("fully.qualified.path.to.Symbol")` — patch at the usage site, not the definition
- Use `mocker.MagicMock()` / `mocker.AsyncMock()` for async calls
- Mock all external dependencies: HTTP clients (`respx`), AWS (botocore `Stubber`), DB, `platform_requests`

**Assertions:**
- `assert_called_once_with(...)` — not `assert_called_once`
- `assert_has_calls([...])` — not `assert_any_call`

**Naming:**
```python
def test_returns_error_when_user_not_found(): ...   # ✅
def test_create_user(): ...                          # ❌ — describes the call, not the behavior
```

**Structure:**
```python
class TestMyService:
    def test_does_x_when_y(self, mocker):
        # Arrange
        dep_mock = mocker.patch("my_pkg.services.my_module.ExternalDep")
        dep_mock.return_value.call.return_value = {"id": "123"}

        # Act
        result = MyService().do_x(payload)

        # Assert
        assert result.id == "123"
        dep_mock.return_value.call.assert_called_once_with(payload)

    def test_raises_when_dep_fails(self, mocker):
        mocker.patch(
            "my_pkg.services.my_module.ExternalDep.call",
            side_effect=RuntimeError("boom"),
        )
        with pytest.raises(RuntimeError):
            MyService().do_x(payload)
```

**Coverage target:** ~90–95% of NEW logic. Do not write tests just to hit a number.

### 5.3 — Run the tests

`./build.sh` runs pytest + behave together. To run only unit tests during development:

```bash
# New tests only
uv run pytest tests/<path>/test_<new_file>.py -v

# Full suite (what build.sh does)
uv run pytest -vv ./tests
```

The build enforces `--cov-fail-under=99` on the full suite. If coverage drops, add tests for any uncovered new lines.

### 5.4 — If tests fail

For each failure:

1. Classify:
   - `TEST_BUG` — incorrect expectation, bad mock, wrong assertion
   - `CODE_BUG` — implementation does not satisfy requirements

2. For `TEST_BUG` → fix the test
3. For `CODE_BUG` → report to orchestrator to return to step 04

---

## Output
```
status: SUCCESS | FAILURE

tests_written:
  - tests/<package>/test_<module>.py

tests_passed: true
failures: 0
coverage: XX%

failure_reason: null | "CODE_BUG" | "TEST_BUG"
notes: |
  Short explanation if something failed
```
