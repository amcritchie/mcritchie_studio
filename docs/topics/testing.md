# Testing

> **When to read this:** Writing new tests, debugging failures, or setting up Playwright/CI.

## Rails Tests

- `bin/rails test` — 418 runs, ~1080 assertions, 5 skips (legacy grade-based ranking tests obsoleted by manual DepthChart)
- Test fixtures for users, agents, tasks, news, contents, skills, teams, people, contracts, athletes (in `test/fixtures/`)
- Test password: "password" for all fixtures
- `log_in_as(user)` helper for integration tests
- **Model tests**: task transitions (valid/invalid), news transitions/slug/position/validations, content slug/stages/position/source_news, user (display_name, admin?, avatar_initials, avatar_color, OAuth/`from_omniauth`), slug generation, team/person/contract associations and validations, athlete slug/validations/person association
- **Controller tests**: sessions (login/logout), registrations (signup), news (CRUD, stage moves, reorder, refine, conclude, create_content, auth enforcement), contents (CRUD, step actions, stage guards, auth enforcement), tasks (CRUD, stage moves, reorder, auth enforcement), rankings (all position pages, sorting, search, team unit, player impact, confirm draft pick with auth/mock conversion/bench rookie/college expiry)

## Playwright E2E Tests

- `npm test` — runs all Playwright tests (13 smoke tests)
- `npm run test:headed` — runs with visible browser
- `npm run test:ui` — opens Playwright UI mode
- **Config**: `playwright.config.js` — Chromium only, port 3000, auto-starts test Rails server
- **Seed**: `e2e/seed.rb` — 1 admin user (alex@test.com / pass), 2 agents, 2 skills, 3 tasks, 2 activities. Idempotent via delete_all.
- **Helper**: `e2e/helpers.js` — `login(page, email, password)`
- **Spec file**: `e2e/smoke.spec.js` — page loads, auth, nav links, theme toggle

## Test invocation gotchas

System Ruby 2.6 is on PATH by default on macOS and breaks `bundle exec`. If tests fail with `cannot load such file -- socket` or `Could not find 'bundler' (2.4.19)`, prepend the brew Ruby PATH:

```bash
PATH="/opt/homebrew/opt/ruby@3.1/bin:/opt/homebrew/lib/ruby/gems/3.1.0/bin:$PATH" bin/rails test
```

See `docs/agents/system/house-burn-down.md` gotchas 1 and 5 for context.
