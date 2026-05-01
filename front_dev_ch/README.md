# Dev Pipeline Agents

Agentic pipeline that takes an ADO ticket from description to passing build, fully automated — for the **CH frontend SvelteKit/TypeScript monorepo**.

## Folder placement

The `.agents/` folder is a standalone git repo that hosts agents for multiple platforms:

```
.agents/
├── .git/
├── .gitignore                      ← covers only this folder
├── back_cr_ch/
│   └── back_cr_ch.agent.md         ← CH backend code review (independent)
├── back_dev_ch/
│   ├── back_dev_ch.agent.md
│   ├── CLAUDE.md
│   └── 01_read_ticket.md … 07_build.md
├── cr_evv/
│   └── code_review.md              ← EVV code review (independent)
├── dev_evv/
│   ├── CLAUDE.md
│   └── 01_read_ticket.md … 07_build.md
├── front_cr_ch/
│   └── front_cr_ch.agent.md        ← CH frontend code review (independent)
└── front_dev_ch/                   ← this folder
    ├── front_dev_ch.agent.md       ← VS Code agent entry point
    ├── CLAUDE.md                   ← orchestrator
    ├── README.md
    ├── 01_read_ticket.md
    ├── 02_git_setup.md
    ├── 03_setup_env.md
    ├── 04_implement.md
    ├── 05_unit_tests.md
    ├── 06_system_tests.md
    └── 07_build.md
```

---

## How to use

In your VS Code MCP chat, type:
```
front_dev_ch 1234
```

The agent entry point (`front_dev_ch.agent.md`) loads the orchestrator `CLAUDE.md`, which drives the full pipeline end-to-end.

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
 ├──▶ 03_setup_env.md      → cd $HOME/code/ch/frontend/web-apps + npm install
 ├──▶ 04_implement.md      → Writes the code (SvelteKit/TypeScript)
 ├──▶ 05_unit_tests.md     → Vitest
 └──▶ 06_build.md          → npm run build + retry loop ↩️
```

> Note: No system tests (behave) step — frontend uses Vitest only.

---

## Independent agents

These agents are **not** part of the automated pipeline and must be invoked directly.

| Agent | Purpose | How to invoke |
|-------|---------|---------------|
| `front_cr_ch.agent.md` | Review all changes on the current branch vs `main` | `front_cr_ch <ticket_id>` or `frontend code review ticket <id>` |

---

## Customization

| What to change | Where |
|----------------|-------|
| Add a new component | `04_implement.md` — add the app to the component table |
| Change max build retries | `06_build.md` — update `max_attempts` |
| Change the npm install step | `03_setup_env.md` |
