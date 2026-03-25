# McRitchie Studio

Central task management and orchestration hub for the McRitchie AI agent system (Alex, Mack, Mason, Turf Monster).

## Dev Server

- **Port 3000** — `bin/rails server` (default)
- Turf Monster runs on port 3001

## Deployment

- **Heroku app**: `mcritchie-studio`
- **URL**: https://app.mcritchie.studio
- **Heroku URL**: https://mcritchie-studio-039470649719.herokuapp.com/
- **Database**: Heroku Postgres (essential-0)
- **DNS**: Google Domains — `app` CNAME → Heroku DNS target
- **Deploy**: `git push heroku main` (then `heroku run bin/rails db:migrate --app mcritchie-studio` if new migrations)
- **Env vars**: `RAILS_MASTER_KEY`, `RAILS_SERVE_STATIC_FILES`, `DATABASE_URL` (auto from addon)
- **ACM**: Enabled (auto SSL via Let's Encrypt)

## Tech Stack

- Ruby 3.1 / Rails 7.2 / PostgreSQL
- Tailwind CSS via CDN (no build step)
- Alpine.js via CDN for interactivity
- Montserrat font (Google Fonts CDN)
- ERB views, import maps, no JS frameworks
- bcrypt password auth + Google OAuth (OmniAuth)
- **Studio engine gem** — `gem "studio", git: "https://github.com/amcritchie/studio.git"`

## Studio Engine

Shared code lives in the [studio engine](https://github.com/amcritchie/studio). This app includes it via `config/initializers/studio.rb`:

```ruby
Studio.configure do |config|
  config.app_name = "McRitchie Studio"
  config.session_key = :studio_user_id
  config.sso_logo = "/studio-logo.svg"
  config.welcome_message = ->(user) { "Welcome to McRitchie Studio, #{user.display_name}!" }
  config.registration_params = [:name, :email, :password, :password_confirmation]
  config.configure_sso_user = ->(user) { user.role = "viewer" }
end
```

**From the engine:** `Studio::ErrorHandling` concern (in ApplicationController), `ErrorLog` model, `Sluggable` concern, auth controllers (sessions, registrations, omniauth_callbacks, error_logs), error log views, generic login/signup views (overridden by app-branded versions).

**Overridden locally:** `sessions/new.html.erb` and `registrations/new.html.erb` (violet-branded with logo).

**Routes:** `Studio.routes(self)` in `config/routes.rb` draws `/login`, `/signup`, `/logout`, `/sso_continue`, `/sso_login`, `/auth/:provider/callback`, `/auth/failure`, `/error_logs`.

**SSO Hub Role:** This app is the central auth hub. On login, `set_app_session` stores `sso_*` fields (including `sso_logo`) in the shared session. Nav bar has a "Turf Monster" CTA button linking to `/sso_login` on the satellite app for one-click SSO. Login page does NOT show "Continue as" (one-way flow — hub only sends, never receives). SSO-created users on satellite apps get `role = "viewer"` via `configure_sso_user`. Requires shared `SECRET_KEY_BASE`.

**Updating:** After changes to the studio repo, run `bundle update studio` here.

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

## Database Standards

- Every table gets `timestamps` (`created_at`, `updated_at`) — no exceptions

## Key Patterns

- **Slug-based FKs** — All foreign keys use slug strings (e.g. `agent_slug`), not integer IDs. Associations: `foreign_key: :agent_slug, primary_key: :slug`.
- **Sluggable concern** (from studio engine) — `before_save :set_slug` via `name_slug` method. Used by User, Agent, Skill, Usage.
- **Task slug** — Immutable random hex generated once on create via `before_validation`. Does NOT use Sluggable.
- **Activity slug** — Set via `after_create` as `"activity-#{id}"` (needs id).
- **ErrorLog** (from studio engine) — `ErrorLog.capture!(exception)` with cleaned backtrace. Target/parent set via ActiveRecord setters after creation.
- **Cost** — Stored as `decimal(10,4)` for sub-cent API pricing precision.

## Routes

### HTML (public monitoring, auth-gated mutations)
- `/` — Dashboard (agents, task pipeline, activity feed)
- `/docs` — Agent docs viewer (read-only, markdown rendered)
- `/docs/*path` — Individual doc viewer
- `/agents` — Agent grid
- `/agents/:slug` — Agent detail (tasks, skills, activity)
- `/tasks` — Filterable task list with stage tabs
- `/tasks/new` — Create task (auth required)
- `/tasks/:slug` — Task detail with transition buttons
- `/activities` — Activity feed
- `/usages` — Usage table
- `/error_logs` — Error log index (search with ILIKE, Esc to clear, 500ms loading animation)
- `/error_logs/:slug` — Error log detail (backtrace, target/parent with copy-to-clipboard console commands, JSON)
- `/login`, `/signup`, `/logout` — Auth

### JSON API (`/api/v1/`)
- `GET/POST /api/v1/tasks` — List/create tasks
- `GET/PATCH /api/v1/tasks/:slug` — Read/update task
- `POST /api/v1/tasks/:slug/{queue,start,complete,fail_task}` — Stage transitions
- `GET/PATCH /api/v1/agents/:slug` — Read/update agent
- `GET/POST /api/v1/activities` — List/create activities
- `GET/POST /api/v1/usages` — List/create usage records

## New Controller Checklist

See top-level `CLAUDE.md` for the full checklist. Quick summary:

1. Identify write actions (create, update, destroy, state transitions)
2. Wrap each with `rescue_and_log(target:, parent:)` + bang methods inside
3. Add outer `rescue StandardError => e` for response control
4. Ensure model has `to_param` returning `slug` if it appears in URLs
5. Read-only actions are covered by Layer 1 automatically

## Error Handling

Every write action MUST use `rescue_and_log` with target/parent context. See top-level `CLAUDE.md` for full pattern docs.

- **Layer 1 (automatic)**: `rescue_from StandardError` via `Studio::ErrorHandling` concern (included in `ApplicationController`) and `Api::V1::BaseController`. Logs via `create_error_log(exception)` (no context). `RecordNotFound` → 404, no logging. Re-raises in dev/test.
- **Layer 2 (required for writes)**: `rescue_and_log(target:, parent:)` wraps write actions. Logs via `create_error_log`, attaches target/parent via ActiveRecord setters. Sets `@_error_logged` flag. Pair with outer `rescue StandardError => e`.
- **Central method**: `create_error_log(exception)` → `ErrorLog.capture!(exception)` → returns record for context attachment
- **Auth + error log controllers**: Provided by studio engine. Do not recreate locally.
- API: `RecordNotFound` → 404 (no log), `RecordInvalid` → 422 (logged via `create_error_log`), `StandardError` → 500 (logged)
- HTML TasksController: all 8 write actions wrapped with `target: @task`
- API TasksController: all 8 write actions wrapped with `target: task`
- API AgentsController#update, ActivitiesController#create, UsagesController#create: all wrapped
- RegistrationsController#create: wrapped with `target: @user`

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
- **Web viewer**: `/docs` — read-only browser for all agent docs, rendered via Redcarpet gem

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
