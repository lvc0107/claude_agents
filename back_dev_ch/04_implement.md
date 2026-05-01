# Subagent 04 — Implement Code

## Role
Implement the code required by the ticket, following the patterns of the specific project type.

## Input
- `component`: sub-project path relative to `promo_applications/` (e.g. `gateways/evv_link`, `lambdas/self_directed/timecard_intake`, `applications/celltrak_admin/web_gateway`)
- `description`: full ticket description
- `acceptance_criteria`: acceptance criteria
- `attempt_number`: current attempt number (1 on first run)
- `build_errors`: errors from the previous build (null on first run)

---

## Tech Stack

All projects are **Python 3.12+** using `pyproject.toml` (managed by **uv**). The project type is determined by the top-level folder and `pyproject.toml` dependencies:

| Top-level folder | Project type | Framework |
|-----------------|-------------|-----------|
| `gateways/` | **FastAPI (REST)** | FastAPI + Pydantic v2 + structlog |
| `platform/` | **FastAPI (Commands)** | FastAPI + CQRS-style commands/queries + event sourcing |
| `applications/` | **Flask** | Flask + Flask-RESTX (legacy) |
| `lambdas/<suite>/<name>/` | **AWS Lambda** | boto3 + structlog + sentry-sdk |
| `crons/<suite>/<name>/` | **Cron Job** | structlog + sentry-sdk |
| `libraries/<name>/` | **Shared Library** | pure Python, no server framework |
| `promo-applications-config/` | **Config** | deployment configs only — no implementation |

---

## Step 4.1 — Build the project (always first)

```bash
./build.sh
```
If there are some errors. Inform to user. This step is required to set the database and to start from a clean stage.

## Step 4.2 — Detect the project type

```bash
ls -la
cat pyproject.toml 2>/dev/null | head -30
```

The top-level folder is the primary signal: `gateways/` → FastAPI REST, `platform/` → FastAPI Commands, `applications/` → Flask, `lambdas/` → Lambda, `crons/` → CronJob, `libraries/` → Library. Confirm with `pyproject.toml` dependencies (`fastapi`, `flask`, `boto3`).

---

## Step 4.3 — Patterns by project type

### � FastAPI (`gateways/<name>/`)

```
<name>/                    ← project root (contains pyproject.toml, build.sh)
└── <name>/                ← Python package
    ├── main.py            ← FastAPI app + router registration
    ├── settings.py        ← env-var settings (Pydantic BaseSettings)
    ├── middleware.py
    ├── sentry.py
    ├── logger.py
    ├── api/               ← one file per resource group
    ├── models/            ← Pydantic v2 request/response models
    ├── services/          ← business logic
    ├── requests/          ← outbound HTTP client wrappers
    ├── validations/       ← input validation helpers
    ├── tests/             ← pytest unit tests
    └── features/          ← behave system tests
```

Endpoint pattern:
```python
from fastapi import APIRouter
from <name>.models.<resource> import <Resource>Request, <Resource>Response

router = APIRouter(prefix="/<resources>", tags=["<resources>"])

@router.get("/", response_model=list[<Resource>Response])
async def list_items() -> list[<Resource>Response]:
    ...

@router.post("/", status_code=201, response_model=<Resource>Response)
async def create_item(body: <Resource>Request) -> <Resource>Response:
    ...
```

Logging — use `structlog`, never `print()` or bare `logging`:
```python
import structlog
logger = structlog.get_logger()
logger.info("event_name", key=value)
```

### 🔷 Flask (`applications/<name>/web_gateway/`)

```
web_gateway/               ← project root (contains pyproject.toml, build.sh)
└── web_gateway/           ← Python package
    ├── web_gateway_app.py ← Flask app factory (create_app)
    ├── apis/              ← Flask-RESTX namespaces (one file per resource)
    ├── models/            ← DB models or dataclasses
    ├── services/          ← business logic
    ├── requests/          ← outbound HTTP helpers
    ├── validations/
    ├── tests/
    └── features/
```

Endpoint pattern:
```python
from flask_restx import Namespace, Resource, fields

api = Namespace('items', description='Item operations')
item_model = api.model('Item', {'name': fields.String, 'value': fields.Float})

@api.route('/')
class ItemList(Resource):
    @api.marshal_list_with(item_model)
    def get(self):
        ...

    @api.expect(item_model)
    def post(self):
        ...
```

### ☁️ AWS Lambda (`lambdas/<suite>/<name>/`)

Each lambda is an **independent sub-project** with its own `pyproject.toml` and `build.sh`.

```
<name>/                    ← project root
├── pyproject.toml
├── build.sh
├── lambda_events/         ← sample event payloads for local testing
├── tests/                 ← pytest unit tests
├── features/              ← behave system tests
└── <name>/                ← Python package
    ├── app.py             ← Lambda entry point (handler function)
    ├── models.py          ← dataclasses / Pydantic models
    ├── settings.py        ← env-var settings
    ├── clients/           ← outbound service clients
    ├── services/          ← business logic
    └── utils.py
```

Handler pattern:
```python
import structlog
import sentry_sdk
from sentry_sdk.integrations.aws_lambda import AwsLambdaIntegration
from <name>.settings import settings
from <name>.services import MyService

logger = structlog.get_logger()

def handler(event: dict, context: object) -> dict:
    logger.info("handler_invoked", event=event)
    result = MyService().process(event)
    return result
```

### ⏰ Cron Job (`crons/<suite>/<name>/`)

```
<name>/                    ← project root
├── pyproject.toml
├── build.sh
├── tests/
├── features/
└── <name>/                ← Python package
    ├── app.py             ← entry point (main function)
    ├── models.py
    ├── services.py
    ├── env.py             ← env-var settings
    └── logs.py
```

Entry point pattern:
```python
import structlog
import sentry_sdk
from <name>.services import MyService
from <name>.logs import setup_logging

logger = structlog.get_logger()

def main() -> None:
    setup_logging()
    sentry_sdk.init(...)
    logger.info("job_started")
    MyService().run()
    logger.info("job_completed")

if __name__ == '__main__':
    main()
```

### 📦 Shared Library (`libraries/<name>/`)

```
<name>/                    ← project root
├── pyproject.toml
├── build.sh
├── version.py
├── tests/
└── <pkg_name>/            ← Python package (snake_case)
    ├── __init__.py
    ├── client.py          ← public API
    ├── models.py
    └── ...
```

No server framework — pure Python. Export the public API from `__init__.py`.

### 🏛️ Platform Service (`platform/<name>/`)

Platform services use **FastAPI with a CQRS-style REST-as-commands pattern** — not RESTful resource routes. All write operations are `POST` endpoints with action-named paths; reads are `GET` endpoints with query-named paths. Both sets live in `api/commands.py` and `api/queries.py` respectively and are registered separately in `main.py`.

```
<name>/                    ← project root
├── pyproject.toml
├── build.sh
├── alembic.ini            ← present if service owns a Postgres DB
├── database_scripts/      ← Alembic migrations
│   └── versions/
├── tests/
├── features/
└── <name>/                ← Python package
    ├── main.py            ← FastAPI app, mounts commands_api + queries_api
    ├── settings.py
    ├── middleware.py
    ├── sentry.py
    ├── logger.py
    ├── lookups.py         ← shared Depends() helpers (e.g. get_target_tenant)
    ├── api/
    │   ├── commands.py    ← all POST /VerbNoun write operations
    │   ├── queries.py     ← all GET /VerbNoun read operations
    │   └── healthcheck.py
    ├── services/          ← business logic
    ├── models.py          ← DB models (SQLAlchemy)
    └── events.py          ← domain events (event sourcing)
```

**`commands.py` pattern** — all endpoints are `POST`, paths are `PascalCase` action names, payloads are `*CmdPayload` models from `platform_requests`:
```python
from typing import Annotated
from fastapi import APIRouter, Depends, status
from platform_requests.models import CreateTenantCmdPayload
from <name>.lookups import get_target_resource
from <name>.services.<resource> import <Resource>Service

api = APIRouter()

@api.post(path="/Create<Resource>", status_code=status.HTTP_201_CREATED)
def create_resource(
    service: Annotated[<Resource>Service, Depends()],
    payload: Create<Resource>CmdPayload,
) -> dict[str, str]:
    return {"<resource>Id": str(service.create(payload).<resource>_id)}

@api.post(path="/Update<Resource>", status_code=status.HTTP_204_NO_CONTENT)
def update_resource(
    service: Annotated[<Resource>Service, Depends()],
    resource: Annotated[<Resource>, Depends(get_target_resource)],
    payload: Update<Resource>CmdPayload,
) -> None:
    service.update(resource, payload)
```

**`queries.py` pattern** — all endpoints are `GET`, paths are `PascalCase` query names:
```python
@api.get(path="/Get<Resource>", status_code=status.HTTP_200_OK)
def get_resource(
    resource: Annotated[<Resource>, Depends(get_target_resource)],
    service: Annotated[<Resource>Service, Depends()],
) -> <Resource>Response:
    return service.get(resource)
```

**`main.py` registration:**
```python
from <name>.api.commands import api as commands_api
from <name>.api.queries import api as queries_api

app.include_router(commands_api)
app.include_router(queries_api)
```

---

## Step 4.4 — Update a dependency library (when required)

If the ticket requires updating a shared library (e.g. `evv-client`, `marshaling`, `system-client`), update `pyproject.toml` with the new pinned version before implementing:

```toml
# pyproject.toml
dependencies = [
    "evv-client>=<new_version>",
    ...
]
```

Then re-run `./build.sh` to pull the updated dependency before writing code that uses the new API.

## Step 4.5 — Explore before writing (always)

Read at least 2 existing files similar to what you're about to implement:
```bash
find . -name "*.py" | xargs grep -l "<keyword_from_ticket>" 2>/dev/null | head -5
```

**Golden rule:** Mirror the style, naming conventions, and structure of the existing code.

---

## Step 4.6 — Database migrations (when schema changes are needed)

Gateways with Postgres use Alembic. If the ticket requires a new table, column, or schema change:

1. Make the model change in `models/` first.

2. Export the Python path so Alembic can find the app modules:
```bash
export PYTHONPATH=$(pwd)
```

3. Apply the current migration state:
```bash
./build.sh
```

4. Generate the new migration:
```bash
alembic revision --autogenerate -m "CH-<ticketID> short description"
```

5. Review the generated file in `db_scripts/versions/` — verify column types, nullability, and indexes are correct.

6. Apply the new migration:
```bash
./build.sh
```
---

## Step 4.7 — On a retry (attempt > 1)

Analyze `build_errors` from the previous attempt and fix **only what is needed**:
- Syntax error → fix that file
- Missing import → add the import
- Broken test → determine if the issue is in the test or the code
- Do not refactor anything unrelated to the error

---

## Checklist before finishing
- [ ] No syntax errors (`python -m py_compile <file>.py`)
- [ ] All imports resolve in the active virtual environment
- [ ] `structlog` used for logging — no `print()` or bare `logging`
- [ ] No hardcoded credentials, tokens, or env-specific values
- [ ] No unresolved `TODO`s that block the build
- [ ] Pydantic v2 models used for FastAPI request/response bodies
- [ ] Pattern is consistent with the rest of the project (mirrored from existing files)
- [ ] Changes scoped to the correct sub-project (no cross-project edits)
- [ ] If schema changed: Alembic migration generated and reviewed

## Output
```
✅ Project type detected: [FastAPI REST | FastAPI Commands | Flask | Lambda | CronJob | Library]
✅ Component path: $HOME/code/ch/backend/promo_applications/<type>/<name>
📁 Files created: [list]
📝 Files modified: [list]
```
