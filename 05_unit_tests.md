# Subagent 05 — Unit Tests

## Role
Write and run unit tests for the code implemented in the previous step.

## Input
- `implemented_files`: list of files created/modified in step 4
- `framework`: test framework (auto-detect from the project)

## Instructions

### 5.1 — Detect the test framework
```bash
cat requirements.txt pyproject.toml 2>/dev/null | grep -i "pytest\|unittest\|nose"
```

Look at existing tests to understand the project's style:
```bash
find . -path "*/test*" -name "*.py" | head -5
# Read one of those files to copy the pattern
```

### 5.2 — Write the tests

For each implemented file, create its corresponding test file.

**Rules for good unit tests:**
- One test per behavior (not per function)
- Use mocks for external dependencies (DB, APIs, filesystem)
- Name tests describing WHAT, not HOW: `test_returns_error_when_user_not_found` ✅
- Don't use assert_any_call. Use assert_called_once_with or assert_has_calls([<list of calls>]) 
- Don't add comments if the action is self-descripted.
- Cover: happy path, edge cases, expected errors
- Minimum 95% coverage of new lines

**Recommended structure:**
```python
# pytest example
class TestUserAuth:
    def test_login_returns_token_for_valid_credentials(self):
        # Arrange
        ...
        # Act
        ...
        # Assert
        ...

    def test_login_raises_error_for_invalid_password(self):
        ...

    def test_login_raises_error_when_user_not_found(self):
        ...
```

### 5.3 — Verify Docker containers are running

Before running tests, ensure the required Docker containers are up:

```bash
# Check if Docker daemon is running
docker info > /dev/null 2>&1 || open -a Docker
```

```bash
# Verify these containers are running:
#   - localdb (postgres, port 5432)
#   - evv_link_payer_mock_server (pretenders, port 8000)
#   - MockServer-FtpScheduler (wiremock, port 8080)
docker ps --format "{{.Names}}" | grep -E "localdb|evv_link_payer_mock_server|MockServer-FtpScheduler"
```

If any container is **not running**, restart them:
```bash
docker restart evv_link_payer_mock_server; docker restart localdb; docker ps
```

Wait a few seconds after restart for the containers to become healthy before proceeding.

### 5.4 — Run the tests
```bash
# Run only the new tests first
pytest tests/test_<new_file>.py -v

# If they pass, run the full suite to catch regressions
pytest --tb=short
```

### 5.4 — If tests fail
- Analyze the error
- Determine if the issue is in the **test** or in the **code**
- Fix and re-run
- After 3 failed attempts → report to the orchestrator with full context

## Output
```
✅ Tests written: [list of test files]
✅ Tests passed: X passed, 0 failed
✅ Coverage: XX%
```
