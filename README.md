# McRitchie Studio

Task management and orchestration hub for the McRitchie AI agent system. Four agents (Alex, Mack, Mason, Turf Monster) run tasks, track usage, and log activities through a web dashboard and JSON API.

**Live**: https://app.mcritchie.studio

## Prerequisites

- Ruby 3.1+
- PostgreSQL 14+
- Node.js 18+ (for Playwright tests)
- Bundler (`gem install bundler`)

## Setup

```bash
git clone https://github.com/amcritchie/mcritchie_studio.git
cd mcritchie_studio
bundle install
bin/rails db:create db:migrate db:seed
```

Seeds create an admin user (`alex@mcritchie.studio` / `password`), 4 agents with avatars, 9 skills, sample tasks, and activities.

## Run

```bash
bin/rails server
```

Runs on **port 3000** by default. Open http://localhost:3000.

## Test

```bash
# Rails unit + integration tests (34 tests)
bin/rails test

# Playwright E2E smoke tests (13 tests)
npm test

# Playwright with visible browser
npm run test:headed
```

## Key Features

- **Dashboard** with agent status, task pipeline (kanban), and activity feed
- **Task management** with enforced state transitions (new, queued, in_progress, done, failed, archived)
- **JSON API** at `/api/v1/` for programmatic task and agent management
- **Expense tracker** with CSV/XLSX parsing and AI categorization (admin-only)
- **Agent docs** viewer at `/docs` with Markdown rendering
- **Dark/light theme** toggle with dynamic color system

## Deploy

```bash
git push heroku main
heroku run bin/rails db:migrate --app mcritchie-studio
```

Platform: Heroku (heroku-24 stack). Required env vars: `RAILS_MASTER_KEY`, `RAILS_SERVE_STATIC_FILES=true`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`.

## Architecture

- Rails 7.2 with ERB views, Tailwind CSS, Alpine.js
- Shared [Studio engine](https://github.com/amcritchie/studio) for auth, error handling, and theme system
- Slug-based foreign keys throughout (not integer IDs)
- All monetary values stored in cents, displayed in dollars

## Development Notes

See [CLAUDE.md](./CLAUDE.md) for detailed development context including model schemas, route maps, error handling patterns, code conventions, and AI agent instructions.
