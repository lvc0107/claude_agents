# Subagent 04 — Implement Code (Frontend)

## Role
Implement the code required by the ticket, following the CH SvelteKit/TypeScript patterns.

## Input
- `component`: sub-app name (e.g. `clearing-house`)
- `description`: full ticket description
- `acceptance_criteria`: acceptance criteria
- `attempt_number`: current attempt number (1 on first run)
- `build_errors`: errors from the previous build (null on first run)

---

## Tech Stack

- **SvelteKit 2** + **Svelte 5** (migrating from v4 — prefer runes)
- **TypeScript 5** strict mode
- **lodash/fp** for compose pipelines in normalizers
- **Vitest 2** for tests (100% coverage enforced)
- **HTTP**: custom `http.ts` wrapper — never use `fetch` directly
- **Sentry** for error tracking
- **Plain CSS** for new styles (not Tailwind)

---

## Step 4.1 — Explore the codebase first (always)

```bash
cd $HOME/code/ch/frontend/web-apps

# Understand the affected domain
ls apps/<component>/src/routes/(protected)/

# Read 2–3 existing files similar to what you'll implement
# Mirror the style, naming conventions, and structure
```

---

## Step 4.2 — Project structure reference

```
apps/<component>/src/
  lib/
    components/    # Shared UI components
    constants/     # apiUrl.js, routes.ts, queryParams.ts
    normalizers/   # Shared data transformers (pure functions)
    services/      # Shared API call functions
    stores/        # Global Svelte stores
    types/         # Global .d.ts type definitions
    utils/         # http.ts, dateFormatter.ts, etc.
  routes/
    (protected)/
      [domain]/
        components/    # Domain-specific .svelte + .state.ts + .test.ts
        normalizers/   # Domain-specific normalizers
        effects/       # Side-effect orchestration (optional)
        stores/        # Domain stores (optional)
        services.ts    # ALL domain API calls live here only
        +page.svelte
        +page.js
    (public)/
```

---

## Step 4.3 — Patterns by change type

### Adding/modifying a service function (`services.ts`)
```typescript
export const fetchMyData = async (
  id: UUID,
): Promise<NormalizedMyData> => {
  try {
    const response = (await http.get(
      `${myBaseUrl}/${id}/endpoint`,
    )) as MyDataType;

    return normalizeMyData(response);
  } catch (error) {
    Sentry.captureException(error);
    return { /* safe fallback */ };
  }
};
```

### Adding/modifying a normalizer
```typescript
// Pure functions only — no HTTP calls, no side effects
import compose from 'lodash/fp/compose';
import map from 'lodash/fp/map';
import { getOr } from '$lib/utils/getOr';

const getItems = getOr([], 'items');

const itemFactory = (item: RawItem) => ({
  id: getOr('', 'id')(item),
  name: getOr('', 'name')(item),
});

export const normalizeMyData = (response: RawMyData): NormalizedMyData => ({
  items: compose(map(itemFactory), getItems)(response),
});
```

### Adding a Svelte component (Svelte 5 runes style)
```svelte
<script lang="ts">
  // Use $state, $derived, $effect (Svelte 5 runes)
  // No $: reactive statements in new/migrated components
  let { label, value }: { label: string; value: string } = $props();
  let localValue = $state(value);
</script>

<div>{label}: {localValue}</div>
```

### Adding a new TypeScript type
- Place in `src/lib/types/<name>.d.ts` if shared app-wide
- Place inline in the domain folder if domain-specific

---

## Step 4.4 — Rules

- [ ] API calls only in `services.ts` — never inside `.svelte` components or stores
- [ ] Normalizers are pure functions — no side effects, no HTTP calls
- [ ] Do not duplicate shared mappers — export and import instead
- [ ] New CSS must be plain CSS, not Tailwind classes
- [ ] No `console.log` — ESLint will fail the build
- [ ] No `$inspect` rune in committed code
- [ ] `Promise.all` tuple order must exactly match the destructured parameter types
- [ ] `localeCompare()` for sort order must use `{ sensitivity: 'base' }`
- [ ] Mutations inside normalizers are forbidden — spread/clone before sort

---

## Step 4.5 — On a retry (attempt > 1)

Analyze `build_errors` and fix **only what is needed**:
- Type error → fix the type annotation
- Import error → add/fix the import
- Test failure → determine TEST_BUG vs CODE_BUG
- ESLint error → fix the lint violation
- Do not refactor anything unrelated to the error

---

## Checklist before finishing
- [ ] No TypeScript errors (`npm run check --workspace=apps/<component>`)
- [ ] No ESLint errors (`npm run lint --workspace=apps/<component>`)
- [ ] No `console.log`, `$inspect`, or commented-out code
- [ ] All imports are correct and available
- [ ] Pattern is consistent with the rest of the domain
- [ ] New `.d.ts` types are in the correct location

## Output
```
📁 Files created: [list]
📝 Files modified: [list]
```
