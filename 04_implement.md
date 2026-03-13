# Subagent 04 — Implement Code

## Role
Implement the code required by the ticket, following the patterns of the specific project type.

## Input
- `component`: folder name (e.g. `evv_auth_service`)
- `description`: full ticket description
- `acceptance_criteria`: acceptance criteria
- `attempt_number`: current attempt number (1 on first run)
- `build_errors`: errors from the previous build (null on first run)

---

## Tech Stack

All projects are **Python**. The project type is determined by the `component` name and its contents:

| Type | How to identify | Framework |
|------|----------------|-----------|
| **FlaskRestX** | contains `app.py` or `wsgi.py` + `flask` in requirements | Flask + Flask-RESTX |
| **FastAPI** | contains `main.py` + `fastapi` in requirements | FastAPI + Uvicorn |
| **AWS Serverless** | component is `evv_link_lamdas` or contains `serverless.yml` / `template.yaml` | AWS Lambda handlers |
| **Cron Job / Monorepo** | component is `evv_ftp_scheduler` or contains `evv_link*` sub-folders | Standalone Python scripts |

---

## Step 4.1 — Detect the project type (always first)

```bash
ls -la
cat requirements.txt 2>/dev/null || cat pyproject.toml 2>/dev/null
grep -i "flask\|fastapi\|boto3\|lambda" requirements.txt pyproject.toml 2>/dev/null
```

---

## Step 4.2 — Patterns by project type

### 🔷 FlaskRestX
```
src/
├── resources/        ← endpoints go here (one file per resource)
├── models/           ← DB models (SQLAlchemy)
├── schemas/          ← serializers / marshmallow
├── services/         ← business logic
└── tests/
```

Endpoint pattern:
```python
from flask_restx import Namespace, Resource, fields

api = Namespace('items', description='Item operations')
item_model = api.model('Item', { ... })

@api.route('/')
class ItemList(Resource):
    @api.marshal_list_with(item_model)
    def get(self):
        ...

    @api.expect(item_model)
    def post(self):
        ...
```

### 🔶 FastAPI
```
src/
├── routers/          ← endpoints go here
├── models/           ← Pydantic models
├── services/         ← business logic
├── db/               ← connection and repositories
└── tests/
```

Endpoint pattern:
```python
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/items", tags=["items"])

class ItemSchema(BaseModel):
    name: str
    value: float

@router.get("/")
async def list_items():
    ...

@router.post("/", status_code=201)
async def create_item(item: ItemSchema):
    ...
```

### ☁️ AWS Serverless (`evv_link_lamdas`)
```
functions/
├── handler_name/
│   ├── handler.py    ← Lambda entry point
│   ├── service.py    ← business logic
│   └── tests/
serverless.yml        ← function and event definitions
```

Handler pattern:
```python
import json

def handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        # logic here
        return {
            'statusCode': 200,
            'body': json.dumps({'result': ...})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```

> ⚠️ No HTTP frameworks. No dependencies not declared in `serverless.yml`.

### ⏰ Cron Jobs / Monorepo (`evv_ftp_scheduler` + `evv_link*` sub-projects)

This is a **monorepo**: the root folder contains multiple independent sub-projects prefixed with `evv_link*`.

```bash
# Identify which sub-project the ticket refers to
ls -la | grep evv_link

# Navigate to the correct sub-project
cd evv_link_<subproject>/
```

Sub-project structure:
```
evv_link_name/
├── main.py           ← cron entry point
├── services/         ← business logic
├── config.py
├── requirements.txt  ← may have its own requirements
└── tests/
```

Cron job pattern:
```python
import logging
from services.processor import Processor

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    logger.info("Starting job...")
    processor = Processor()
    result = processor.run()
    logger.info(f"Job completed: {result}")

if __name__ == '__main__':
    main()
```

---

## Step 4.3 — Explore before writing (always)

Read at least 2 existing files similar to what you're about to implement:
```bash
find . -name "*.py" | xargs grep -l "<keyword_from_ticket>" 2>/dev/null | head -5
```

**Golden rule:** Mirror the style, naming conventions, and structure of the existing code.

---

## Step 4.4 — On a retry (attempt > 1)

Analyze `build_errors` from the previous attempt and fix **only what is needed**:
- Syntax error → fix that file
- Missing import → add the import
- Broken test → determine if the issue is in the test or the code
- Do not refactor anything unrelated to the error

---

## Checklist before finishing
- [ ] No syntax errors (`python -m py_compile <file>.py`)
- [ ] All imports are correct and available in the environment
- [ ] No hardcoded credentials
- [ ] No unresolved `TODO`s that block the build
- [ ] Pattern is consistent with the rest of the project
- [ ] In monorepo: changes are scoped to the correct sub-project

## Output
```
✅ Project type detected: [FlaskRestX | FastAPI | Serverless | CronJob]
📁 Files created: [list]
📝 Files modified: [list]
```
