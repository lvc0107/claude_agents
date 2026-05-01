# Dev Pipeline Agents

Agentic pipeline that takes an ADO ticket from description to passing build, fully automated.

## Folder placement

The `.agents/` folder is a standalone git repo that hosts agents for multiple platforms:

```
.agents/
├── .git/
├── .gitignore                      ← covers only this folder
├── back_cr_ch/
│   └── back_cr_ch.agent.md         ← CH backend code review (independent)
├── back_dev_ch/                    ← this folder
│   ├── back_dev_ch.agent.md        ← VS Code agent entry point
│   ├── CLAUDE.md                   ← orchestrator
│   ├── README.md
│   ├── 01_read_ticket.md
│   ├── 02_git_setup.md
│   ├── 03_setup_env.md
│   ├── 04_implement.md
│   ├── 05_unit_tests.md
│   ├── 06_system_tests.md
│   └── 07_build.md
├── cr_evv/
│   └── code_review.md              ← EVV code review (independent)
├── dev_evv/
│   ├── CLAUDE.md
│   ├── README.md
│   └── 01_read_ticket.md … 07_build.md
├── front_cr_ch/
│   └── front_cr_ch.agent.md        ← CH frontend code review (independent)
└── front_dev_ch/
    ├── front_dev_ch.agent.md
    ├── CLAUDE.md
    ├── README.md
    └── 01_read_ticket.md … 07_build.md
```

### Do I need to update each project's `.gitignore`?

**No.** Because the `.agents/` folder lives at the CH root level — outside every project repo — the individual projects never see these files. Their `.gitignore` files are completely unaffected.

The only `.gitignore` you need is the one inside `.agents/` itself, which excludes runtime files (`TICKET_STATE.md`, `build_output.log`) that get generated when the pipeline runs.

> **Note:** If `$HOME/code/ch/backend/` is itself a git repo, add `.agents/` to its root `.gitignore` if you don't want to commit the agent files.

---

## How to use

In your VS Code MCP chat, type:
```
Run the full pipeline for ticket 1234
```

The agent entry point (`back_dev_ch.agent.md`) loads the orchestrator `CLAUDE.md`, which drives the full pipeline end-to-end.

---

## Pipeline flow

```
User
 │
 ▼
CLAUDE.md (Orchestrator)
 │
 ├──▶ 01_read_ticket.md    → Reads ADO ticket, extracts fields
 ├──▶ 02_git_setup.md      → git checkout / pull / branch
 ├──▶ 03_setup_env.md      → cd $HOME/code/ch/backend/promo_applications/<type>/<name> + .venv
 ├──▶ 04_implement.md      → Writes the code
 ├──▶ 05_unit_tests.md     → pytest
 ├──▶ 06_system_tests.md   → behave features/
 └──▶ 07_build.md          → ./build.sh + retry loop ↩️
```

---

## Independent agents

These agents are **not** part of the automated pipeline and must be invoked directly.

| Agent | Purpose | How to invoke |
|-------|---------|---------------|
| `back_cr_ch.agent.md` | Review all changes on the current branch vs `main` | `back_cr_ch <ticket_id>` or `backend code review ticket <id>` |

---

## Customization

| What to change | Where |
|----------------|-------|
| Add a new project type | `04_implement.md` — add a new row to the type table and a pattern section |
| Change max build retries | `07_build.md` — update `max_attempts` |
| Add a PR creation step | Create `agents/08_create_pr.md` and reference it from `CLAUDE.md` |
| Change the venv activation order | `03_setup_env.md` — Step 3.4 |
