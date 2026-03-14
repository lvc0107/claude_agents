# Subagent 03 — Git Setup

## Role
Clean the local repo state and create the branch for the ticket.

## Input
- `ticket_id`: ticket ID number (e.g. `123456`)
- `description`: short description of the ticket (e.g. `Add user authentication`)

## Branch naming convention

```
EVV-<ticket_id>_Description-separated-by-dashes
```

Examples:
- `EVV-123456_Add-user-authentication`

Rules: only alphanumeric and hyphens after the first underscore. No underscores in the description part.
Pattern enforced by pre-commit hook: `^EVV-[0-9]+_[A-Za-z0-9-]+$`

## Instructions

### 3.1 — Discard local changes
```bash
git stash save "PREVIUS changes to <ticket_id>"
```
This discards any uncommitted changes. This is intentional — we always start from a clean state.

### 3.2 — Pull latest from remote
```bash
git pull --rebase
```
If there are rebase conflicts:
- Abort with `git rebase --abort`
- Report to the orchestrator with conflict details

### 3.3 — Create the branch
```bash
git checkout -b "EVV-<ticket_id>_<description-with-dashes>"
```

Verify it was created correctly:
```bash
git branch --show-current
```

---

## Validations

| Condition | Action |
|-----------|--------|
| Not a git repository | Report critical error — stop pipeline |
| `git pull --rebase` has conflicts | Abort and report to the user |
| Branch already exists | Use `git checkout <branch_name>` (without `-b`) |
| All OK | Continue |

## Output
```
✅ Repo cleaned (git checkout .)
✅ Updated from remote (git pull --rebase)
✅ Active branch: EVV-<ticket_id>_<description-with-dashes>
```
