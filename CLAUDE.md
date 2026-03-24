# McRitchie Studio

Central task management and orchestration hub for the McRitchie AI agent system (Alex, Mack, Mason, Turf Monster).

## Dev Server

- **Port 3000** — `bin/rails server` (default)
- Turf Monster runs on port 3001

## Tech Stack

- Ruby 3.1 / Rails 7.2 / PostgreSQL
- Tailwind CSS via CDN (no build step)
- Alpine.js via CDN for interactivity
- Montserrat font (Google Fonts CDN)
- ERB views, import maps, no JS frameworks
- bcrypt password auth + Google OAuth (OmniAuth)

## Branding

- **Primary**: `#8E82FE` Violet — CTAs, buttons, links, hovers, form focus
- **Background**: `#1A1535` Deep Navy — body bg, card bg
- **Success accent**: `#06D6A0` Mint — flash notices, success toasts, active status dots, "Start" button, in_progress badges
- **Text**: `#FFFFFF` White — headings, primary text
- **Font**: Montserrat (weights 400-900)
- **Logo**: SVG icon (`app/assets/images/logo-icon.svg`) + "McRitchie **Studio**" (Studio in violet)
- Tailwind custom colors:
  - `violet` (5-step: 100 `#EAE8FF`, 300 `#C5C0FE`, 500 `#8E82FE`, 700 `#6558E0`, 900 `#3D2FB5`)
  - `mint` (full scale, accent only)
  - `navy` (full scale, backgrounds)
  - Neutrals: `mist`, `lavender`, `slate`, `charcoal`, `midnight`
  - Accents: `ember`, `gold`, `magenta`
- Stage badges: blue=new, yellow=queued, mint=in_progress, green=done, red=failed, gray=archived

## Models

- **User** — name, email, password_digest, provider, uid, role (admin/viewer), slug. `has_secure_password`, `from_omniauth`.
- **Agent** — name, slug (unique), status (active/paused/inactive), agent_type, title, description, config (jsonb), metadata (jsonb), last_active_at. Has many tasks/activities/usages/skills.
- **Task** — title, slug (unique, random hex, immutable), description, stage (new/queued/in_progress/done/failed/archived), priority (0-2), agent_slug FK, required_skills (jsonb), result (jsonb), error_message, timestamps per stage. Does NOT use Sluggable.
- **Skill** — name, slug (unique), category, description, config (jsonb). Has many agents through skill_assignments.
- **SkillAssignment** — agent_slug FK, skill_slug FK, proficiency. Join table, no slug.
- **Activity** — agent_slug FK, activity_type, description, task_slug FK, metadata (jsonb), slug (set via after_create).
- **Usage** — agent_slug FK, period_date, period_type, model, tokens_in/out, api_calls, cost (decimal 10,4), tasks_completed/failed, metadata (jsonb), slug.
- **ErrorLog** — message, inspect, backtrace (JSON), polymorphic target/parent, target_name, parent_name, slug.

## Key Patterns

- **Slug-based FKs** — All foreign keys use slug strings (e.g. `agent_slug`), not integer IDs. Associations: `foreign_key: :agent_slug, primary_key: :slug`.
- **Sluggable concern** — `before_save :set_slug` via `name_slug` method. Used by User, Agent, Skill, Usage.
- **Task slug** — Immutable random hex generated once on create via `before_validation`. Does NOT use Sluggable.
- **Activity slug** — Set via `after_create` as `"activity-#{id}"` (needs id).
- **ErrorLog.capture!** — `ErrorLog.capture!(exception, target:, parent:)` with cleaned backtrace.
- **Cost** — Stored as `decimal(10,4)` for sub-cent API pricing precision.

## Routes

### HTML (public monitoring, auth-gated mutations)
- `/` — Dashboard (agents, task pipeline, activity feed)
- `/agents` — Agent grid
- `/agents/:slug` — Agent detail (tasks, skills, activity)
- `/tasks` — Filterable task list with stage tabs
- `/tasks/new` — Create task (auth required)
- `/tasks/:slug` — Task detail with transition buttons
- `/activities` — Activity feed
- `/usages` — Usage table
- `/error_logs` — Error log index/show
- `/login`, `/signup`, `/logout` — Auth

### JSON API (`/api/v1/`)
- `GET/POST /api/v1/tasks` — List/create tasks
- `GET/PATCH /api/v1/tasks/:slug` — Read/update task
- `POST /api/v1/tasks/:slug/{queue,start,complete,fail_task}` — Stage transitions
- `GET/PATCH /api/v1/agents/:slug` — Read/update agent
- `GET/POST /api/v1/activities` — List/create activities
- `GET/POST /api/v1/usages` — List/create usage records

## Error Handling

- `ErrorLog.capture!(exception, target:, parent:)` — DB only, no external services
- `rescue_and_log(target:, parent:)` — ApplicationController helper
- `RecordNotFound` = expected (no log), `RecordInvalid`/`RuntimeError` = log
- API controllers rescue `RecordNotFound` → 404, `RecordInvalid` → 422

## Seeds

- Admin: `alex@mcritchie.studio` / `pass`
- 4 agents: Alex (orchestrator), Mack (worker), Mason (specialist), Turf Monster (specialist)
- 9 skills across data/development/infrastructure/system/domain
- 15 skill assignments
- 8 sample tasks in various stages
- 6 sample activities
- All idempotent via `find_or_create_by!`

## Docs

Agent system documentation at `docs/agents/`:
- `system/` — Architecture, bootstrap, comms protocol, coding standards, credentials
- `agents/{alex,mack,mason,turf_monster}/` — Role and soul docs per agent
- `shared/MEMORY.md` — Cross-agent shared memory

## Workflow Preferences

- **Debugging**: STOP on bugs — show the issue and ask before fixing
- **Testing**: Write tests alongside features
- **Database**: Migrate and seed freely without asking
- **Git**: Small frequent commits, push immediately
- **UI**: Style as we build using brand palette
- **Decisions**: Present 2-3 options briefly with a recommendation
- **Refactoring**: Proactively clean up code smells

## Session Protocol

When the user signals end of session, review and refactor ALL CLAUDE.md files to reflect current state.
