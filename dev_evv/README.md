# Dev Pipeline Agents

Agentic pipeline that takes an ADO ticket from description to passing build, fully automated.

## Folder placement

These files live at the **EVV root**, not inside any individual project:

```
$HOME/code/EVV/
├── .agents/                    ← this folder
│   ├── CLAUDE.md               ← orchestrator
│   ├── .gitignore              ← covers only this folder
│   ├── dev_evv/
│   │   ├── 01_read_ticket.md
│   │   ├── 02_setup_env.md
│   │   ├── 03_git_setup.md
│   │   ├── 04_implement.md
│   │   ├── 05_unit_tests.md
│   │   ├── 06_system_tests.md
│   │   ├── 07_build.md
│   ├── cr_evv/
│   │   └── code_review.md      ← independent (not part of the pipeline)
│   └── README.md
├── evv_auth_service/           ← individual projects untouched
├── evv_payments/
├── evv_link_lamdas/
├── evv_ftp_scheduler/
└── ...
```

### Do I need to update each project's `.gitignore`?

**No.** Because the `.agents/` folder lives at the EVV root level — outside every project repo — the individual projects never see these files. Their `.gitignore` files are completely unaffected.

The only `.gitignore` you need is the one inside `.agents/` itself, which excludes runtime files (`TICKET_STATE.md`, `build_output.log`) that get generated when the pipeline runs.

> **Note:** If `$HOME/code/EVV/` is itself a git repo, add `.agents/` to its root `.gitignore` if you don't want to commit the agent files.

---

## How to use

In your VS Code MCP chat, type:
```
Run the full pipeline for ticket 1234
```

The orchestrator reads `CLAUDE.md`, understands the full flow, and runs it end-to-end.

---

## Pipeline flow

```
User
 │
 ▼
CLAUDE.md (Orchestrator)
 │
 ├──▶ 01_read_ticket.md    → Reads ADO ticket, extracts fields
 ├──▶ 02_setup_env.md      → cd $HOME/code/EVV/<component> + venv
 ├──▶ 03_git_setup.md      → git checkout / pull / branch
 ├──▶ 04_implement.md      → Writes the code
 ├──▶ 05_unit_tests.md     → pytest
 ├──▶ 06_system_tests.md   → behave features/
 └──▶ 07_build.md          → ./build.sh + retry loop ↩️
```

---

---

## Independent agents

These agents are **not** part of the automated pipeline and must be invoked directly.

| Agent | Purpose | How to invoke |
|-------|---------|---------------|
| `code_review.md` | Review all changes on the current branch vs `main` | `Code review` or `Run a code review on branch EVV-1234_my-feature` |

---

## Customization

| What to change | Where |
|----------------|-------|
| Add a new project type | `04_implement.md` — add a new row to the type table and a pattern section |
| Change max build retries | `07_build.md` — update `max_attempts` |
| Add a PR creation step | Create `agents/08_create_pr.md` and reference it from `CLAUDE.md` |
| Change the venv activation order | `02_setup_env.md` — Step 2.4 |
