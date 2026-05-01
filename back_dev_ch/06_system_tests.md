# Subagent 06 — System Tests (Behave)

## Role
Write and run system tests using Behave (BDD) to verify end-to-end behavior described in the ticket.

## Input
- `description`: ticket description
- `acceptance_criteria`: acceptance criteria — each maps directly to a Behave scenario

---

## Instructions

### 6.1 — Explore the features structure

```bash
ls features/
ls features/steps/
find features/ -name "*.feature" | head -5
```

Read 1–2 existing `.feature` files and `features/environment.py` to understand the project's setup and reusable fixtures.

### 6.2 — Create the `.feature` file

Name the file after the **action/resource**, not the ticket ID:
- ✅ `features/create_tenant.feature`
- ❌ `features/CH-1234_create_tenant.feature`

Each acceptance criterion → at least 1 scenario. Mirror the exact style of existing features in the project:

**Gateway style** (resource-centric, `Scenario Outline` for variations):
```gherkin
Feature: <Action Resource>

  Scenario: Happy Path
    Given the <Service> is running
      And a valid request to <action> a <Resource>
      And the request includes valid authentication evidence
     When the <Service> receives the request to <action> the <Resource>
     Then the <Service> returns the status code 2XX

  Scenario: <Error case>
    Given the <Service> is running
      And ...
     When ...
     Then the <Service> returns the status code 4XX
      And the <Service> notifies the requester of only these validation errors
      | loc   | type  | message |
      | field | type  | message |
```

**Platform Commands style** (action-centric, verifies event sourcing):
```gherkin
Feature: <Action> <Resource>

  Scenario: Happy Path
    Given the <Service> app is running
      And a valid request to <Action> a <Resource>
      And the request includes a valid System Owner token
     When the <Service> app receives the request to <Action> the <Resource>
     Then the <Service> app returns HTTP 204
      And the <Service> app records the "<EventName>" event

  Scenario: <Resource> Does NOT Exist
    Given the <Service> app is running
      And ...
     When ...
     Then the <Service> app returns HTTP 404
```

### 6.3 — Implement the steps

**File placement:**
1. If an existing steps file already covers the same resource/flow → **append** to it
2. If the flow is new → create `features/steps/<resource>.py` — **never include ticket ID in filename**

```bash
# Find reusable steps first
grep -r "def step_" features/steps/ | head -20
```

Steps pattern (mirrors existing code — use the same `context` attributes):
```python
from behave import given, when, then

@given("a valid request to <action> a <Resource>")
def step_impl(context):
    context.request = {
        "method": "POST",
        "url": "/<ActionResource>",
        "json": <Resource>PayloadBuilder(...).payload(),
    }

@when("the <Service> app receives the request to <action> the <Resource>")
def step_impl(context):
    context.response = context.client.request(**context.request)

@then("the <Service> app returns HTTP {status_code:d}")
def step_impl(context, status_code):
    assert context.response.status_code == status_code
```

**Reuse existing steps** — do not duplicate `Given the X is running`, common auth steps, or HTTP assertion steps.

### 6.4 — `features/environment.py` — do NOT modify unless adding a new fixture

The `environment.py` already sets up the test client, mocks, and fixtures in `before_all` / `before_scenario`. Understand what is already available on `context` before writing steps:

| Project type | Key context attributes |
|---|---|
| Gateway | `context.client`, `context.respx_mock`, `context.platform_mock`, `context.id_resolver_mock` |
| Platform | `context.client`, `context.event_stream`, `context.data_store`, `context.respx_mock` |
| Lambda | `context.s3_stubber`, `context.config_cache_mock` (varies per lambda) |

### 6.5 — Run the tests

`./build.sh` runs behave automatically after pytest. To run only behave during development:

```bash
# Single feature
uv run behave features/<feature_name>.feature -v

# Full suite (what build.sh does)
uv run behave --junit --junit-directory=reports/tests
```

### 6.6 — If tests fail
- Step implementation error → fix the step
- Business logic error → report to the orchestrator to return to step 4
- Environment/mock error → report with full context (missing stub, unconfigured mock, etc.)

---

## Output
```
✅ Feature file: features/<action_resource>.feature
✅ Steps: features/steps/<resource>.py (created | appended)
✅ Scenarios: X passed, 0 failed
```
