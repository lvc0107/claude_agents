# Subagent 01 — Read Ticket

## Role
Read and parse an ADO ticket, extracting all information needed by the pipeline.

## Input
- `ItemID`: ticket number (e.g. `1234`)

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
   get_ado_work_item <ItemID>
   ```

3. Extract the following fields. If any field is missing, record it as `null`:

   | Field | Description |
   |-------|-------------|
   | `title` | Ticket title |
   | `description` | Full description of the work to be done |
   | `component` | Folder name inside `$HOME/code/EVV/` |
   | `acceptance_criteria` | Acceptance criteria |
   | `item_type` | Bug / Feature / Task |

4. Generate the branch name:
   - Take the title
   - Replace spaces with `_`
   - Remove special characters: `/ \ : * ? " < > | # @ ! $ % ^ & ( )`
   - Limit to 60 characters total
   - Final format: `EVV-<ItemID>_<processed_title>`

5. Write a `TICKET_STATE.md` file at `$HOME/code/EVV/`:

```markdown
# Ticket State

## Info
- **ItemID**: <ItemID>
- **Branch**: EVV-<ItemID>_<title>
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

Projects live in `$HOME/code/EVV/` with the prefix `evv_*`.
Examples: `evv_auth_service`, `evv_payments`, `evv_ftp_scheduler`.

**If `component` is present in the ticket:** use it directly.

**If `component` is empty or missing:**
1. Run `ls $HOME/code/EVV/` to get the real list of projects
2. **Pause the pipeline** and ask the user:

```
⚠️  Ticket EVV-<ItemID> has no 'Component' field defined.

Available projects in $HOME/code/EVV/:
  - evv_auth_service
  - evv_payments
  - evv_ftp_scheduler
  (actual output of ls)

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
  "branch_name": "EVV-1234_Add_user_authentication",
  "component": "evv_auth_service",
  "description": "...",
  "acceptance_criteria": "..."
}
```

## Common Errors
- **Ticket not found**: Report to the user with the exact ItemID
- **Vague description**: Continue but note in `TICKET_STATE.md` that clarification may be needed
