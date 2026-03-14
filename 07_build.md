# Subagent 07 — Build & Iterate

## Role
Run the build and coordinate the correction loop until the build is green.

## Input
- `attempt_number`: current attempt number
- `max_attempts`: 10 (default)

## Instructions

### 7.1 — Verify Docker containers are running

Before running the build, ensure the required Docker containers are up:

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

### 7.2 — Run the build
```bash
./build.sh 2>&1 | tee build_output.log
echo "EXIT_CODE: $?"
```

Capture all output — both stdout and stderr.

### 7.3 — Analyze the result

#### ✅ Build passed (exit code 0)
```bash
grep -i "error\|failed\|failure" build_output.log
```
If no errors → **Pipeline complete**. Proceed to step 7.4.

#### ❌ Build failed (exit code != 0)

Classify the error type:

| Error Type | Example | Action |
|------------|---------|--------|
| **Syntax** | `SyntaxError`, `unexpected token` | Return to step 4 (code) |
| **Import / Dependency** | `ModuleNotFoundError`, `cannot find module` | Check imports, review requirements |
| **Test failure** | `FAILED tests/`, `AssertionError` | Return to step 5 (unit tests) |
| **Behave failure** | `0 features passed`, `Scenario FAILED` | Return to step 6 (system tests) |
| **Compilation** | `cannot compile`, `build error` | Return to step 4 |
| **Linting** | `flake8`, `pylint`, `ruff` errors | Fix in step 4 |

### 7.4 — Pre-commit formatting

Before committing, always run pre-commit to auto-format and lint:

```bash
pre-commit run --all-files
git add .
```

Repeat until all hooks pass with no modifications:
```bash
pre-commit run --all-files
# Expected: all hooks show "Passed"
```

If a hook keeps failing after 3 iterations, classify the error and return to the appropriate step.

### 7.5 — Iteration loop

```
If attempt < max_attempts:
  1. Log the error in TICKET_STATE.md
  2. Send context to the orchestrator:
     - Error type detected
     - Relevant lines from the log
     - Files involved
  3. Orchestrator delegates to subagent 4, 5, or 6
  4. attempt += 1
  5. Re-run ./build.sh

If attempt >= max_attempts:
  → Escalate to the user with a full report
```

### 7.6 — Commit the changes

Once the build is green and pre-commit passes, commit all staged changes:

```bash
git add .
git commit -m "EVV-<ticket_id> <Original message from the ticket title>"
```

Use the exact ticket title as the commit message body (e.g. `EVV-123456 Add user authentication`).

---

### 7.7 — Rebase onto latest main/master

The branch may have been created from an older commit. Always sync with the remote before finishing:

```bash
git fetch --all
```

Check if the base branch has new commits ahead of your branch:
```bash
git log HEAD..origin/master --oneline
# or if the default branch is main:
git log HEAD..origin/main --oneline
```

If there are new commits, rebase:
```bash
git rebase origin/master
# or: git rebase origin/main
```

#### If there are conflicts

Resolve each conflicting file, then continue:
```bash
# 1. Open the conflicting file(s) and fix the conflict markers
# 2. Stage the resolved file(s)
git add <conflicting_file>

# 3. Continue the rebase
git rebase --continue
```

Repeat until `git rebase --continue` completes with no more conflicts.

If the rebase cannot be resolved, abort and escalate:
```bash
git rebase --abort
# → Report to the user with full conflict details
```

#### After a successful rebase — re-run the build

A rebase can introduce regressions. Always rebuild after rebasing:

```bash
./build.sh 2>&1 | tee build_output.log
echo "EXIT_CODE: $?"
```

If the build fails after rebase, return to the appropriate step (4, 5, or 6) to fix the issue,
then re-commit and re-rebase.

---

### 7.8 — Final report

Update `TICKET_STATE.md`:
```markdown
## Build Result
- **Status**: SUCCESS
- **Attempts**: <N>
- **Timestamp**: <date>

## Changed files
<output of git diff --stat origin/master>
# or: <output of git diff --stat origin/main>

```

Show summary to the user:
```
Pipeline completed successfully!

Ticket: EVV-<ticket_id>
Branch: EVV-<ticket_id>_<description>
Build: PASSED (attempt <N>)
Rebased onto: origin/master (or origin/main)

Changed files:
  - src/auth/user_auth.py (new)
  - tests/test_user_auth.py (new)
  - features/EVV-<ticket_id>.feature (new)

Suggested next steps:
  1. Review the generated code
  2. git push origin EVV-<ticket_id>_<description>
  3. Create a Pull Request in ADO
```

## Output states
```
Build attempt <N>/<max>: RUNNING...
Build attempt <N>/<max>: FAILED — [error type]
Build attempt <N>/<max>: SUCCESS
Committed: EVV-<ticket_id> <message>
Rebase: OK — branch is up to date with origin/master  # or: origin/main
Rebase: CONFLICTS — resolved and continued
Build after rebase: PASSED
```


