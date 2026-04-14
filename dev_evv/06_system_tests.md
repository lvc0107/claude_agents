# Subagent 06 — System Tests (Behave)

## Role
Write and run system tests using Behave (BDD) to verify the end-to-end behavior described in the ticket.

## Input
- `description`: ticket description
- `acceptance_criteria`: acceptance criteria — these map directly to Behave scenarios

## Instructions

### 6.1 — Explore existing tests
```bash
find . -name "*.feature" | head -10
ls features/
ls features/steps/
```
Read 1–2 existing `.feature` files to understand the project's style.

### 6.2 — Create the `.feature` file

Each acceptance criterion becomes a Behave scenario:

```gherkin
# features/EVV-<ticket_id>_<description>.feature
Feature: <Ticket title>
  As a <user/system>
  I want <functionality>
  So that <benefit>

  Background:
    Given the system is initialized
    And the database has test data

  Scenario: Happy path — <main criterion>
    Given <precondition>
    When <action>
    Then <expected result>

  Scenario: Error case — <error criterion>
    Given <error precondition>
    When <action>
    Then <expected error result>
```

**Rule:** Each acceptance criterion from the ticket → at least 1 scenario.

### 6.3 — Implement the Steps

```bash
# Find existing steps you can reuse
grep -r "def step_" features/steps/ | head -20
```

Create the steps file at `features/steps/EVV-<ticket_id>_steps.py`:
approach:
  1. Try to append the tests to an exising file if the existing file is already testing the class, or module
  2. If the component is truly new. Then create a new step file but DON'T use the ticket id on it because is hard to track.


```python
from behave import given, when, then

@given('<precondition>')
def step_impl(context):
    ...

@when('<action>')
def step_impl(context):
    ...

@then('<expected result>')
def step_impl(context):
    ...
```

**Reuse existing steps** when equivalent — do not duplicate.

### 6.4 — Verify Docker containers are running

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

### 6.5 — Run the tests
```bash
# Run only the new feature
behave features/EVV-<ticket_id>_<description>.feature -v

# If it passes, run the full suite
behave --no-capture
```

### 6.6 — If tests fail
- Step implementation error → fix the step
- Business logic error → report to the orchestrator to return to step 4
- Environment/config error → report with full context

## Output
```
✅ Feature file created: features/EVV-<ticket_id>_<description>.feature
✅ Steps implemented: features/steps/EVV-<ticket_id>_steps.py
✅ Scenarios: X passed, 0 failed
```
