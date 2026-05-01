# Subagent 01 — Read Ticket

## Role
Read and parse an ADO ticket, extracting all information needed by the pipeline.

## Input
- `ticket_id`: ticket number (e.g. `1234`)

## Instructions

1. Log in to Azure:
   ```bash
   az login --allow-no-subscriptions
   ```
   Wait for the browser authentication to complete before continuing.

   | Condition | Action |
   |-----------|--------|
   | Login succeeds | Continue to step 2 |
   | Browser doesn't open | Try `az login --use-device-code --allow-no-subscriptions` |
   | Login fails | Report error to the user — do not continue |

2. Call the MCP command:
   ```
   get_ado_work_item <ticket_id>
   ```

3. Extract the following fields. If any field is missing, record it as `null`:

   | Field | Description |
   |-------|-------------|
   | `title` | Ticket title |
   | `description` | Full description of the work to be done |
   | `component` | Folder name inside `HOME/code/ch/backend/` |
   | `acceptance_criteria` | Acceptance criteria |
   | `item_type` | Bug / Feature / Task |

Please note that the work will involve several projects. It is quite common for Flask, FastAPI, Lambda functions, and cron jobs to utilize the following libraries:
- TODO complete with the actual libraries


Therefore, if work on these dependencies becomes necessary, the process must begin as follows:
1) Apply the entire sub-agent workflow for that specific library.
2) Once the library has been updated, we can proceed with working over other library(if is required) or on the main component.
3) If the component is requesting to implement a new API, or add new endpoints to an existing API in a Flask or FastAPI, we must:
   3.1) follow the normal flow: subagents01-07
   3.2) Add the new API to the rest_client library. Here also we have to  run subagents02-07


4. Generate the branch name:
   - Take the title
   - Replace spaces with `_`
   - Remove special characters: `/ \ : * ? " < > | # @ ! $ % ^ & ( )`
   - Limit to 60 characters total
   - Separate words in title with '-'
   - Final format: `CH-<ticket_id>_<processed_title>`

5. Write a `TICKET_STATE.md` file at `HOME/code/ch/backend/`:

```markdown
# Ticket State

## Info
- **ticket_id**: <ticket_id>
- **Branch**: CH-<ticket_id>_<title>
- **Component**: <component>
- **Status**: IN_PROGRESS

## Description
<full description>

## Acceptance Criteria
<criteria>

## Build Attempts
- Attempt 1: PENDING
```

---

## Handling the Component Field (critical)

Projects live in `HOME/code/ch/backend/`

**If `component` is present in the ticket:** use it directly.

**If `component` is empty or missing:**
1. Run `ls HOME/code/ch/backend/` to get the real list of projects
2. **Pause the pipeline** and ask the user:

```
⚠️  Ticket CH-<ticket_id> has no 'Component' field defined.

Available projects in HOME/code/ch/backend/:
TODO

Which project does this ticket belong to?
```
3. Wait for the user's response before continuing.

---

## Expected Output
Return a summary for the orchestrator to continue:
```json
{
  "item_id": "1234",
  "title": "Add user authentication",
  "branch_name": "CH-1234_Add_user_authentication",
  "component": "ch_auth_service",
  "description": "...",
  "acceptance_criteria": "..."
}
```

## Common Errors
- **Ticket not found**: Report to the user with the exact ticket_id
- **Vague description**: Continue but note in `TICKET_STATE.md` that clarification may be needed
