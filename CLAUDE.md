# McRitchie Studio

Central task management and orchestration hub for the McRitchie AI agent system (Alex, Mack, Mason, Turf Monster).

## Dev Server

- **Port 3000** — `bin/rails server` (default)
- Turf Monster runs on port 3001
- Tax Studio runs on port 3003

## Deployment

- **Heroku app**: `mcritchie-studio`
- **URL**: https://app.mcritchie.studio
- **Heroku URL**: https://mcritchie-studio-039470649719.herokuapp.com/
- **Database**: Heroku Postgres (essential-0)
- **DNS**: Google Domains — `app` CNAME → Heroku DNS target
- **Deploy**: `git push heroku main` (then `heroku run bin/rails db:migrate --app mcritchie-studio` if new migrations)
- **Env vars**: `RAILS_MASTER_KEY`, `RAILS_SERVE_STATIC_FILES`, `DATABASE_URL` (auto), `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `ANTHROPIC_API_KEY` (for AI chat)
- **ACM**: Enabled (auto SSL via Let's Encrypt)

## Public Assets

- `public/agents/` — Agent avatar images (alex.png, alex-photo.png, mack.png, mason.png, turf-monster.png)
- `public/denver-hero.avif` — Landing page hero background (Denver skyline)
- `public/studio-logo.svg` — SSO logo (shared with satellite apps)
- `public/favicon.png`, `public/icon.png`, `public/logo-icon.svg` — App icons

## Tech Stack

- Ruby 3.1 / Rails 7.2 / PostgreSQL
- Tailwind CSS via `tailwindcss-rails` gem (compiled with `@apply` support, not CDN)
- Alpine.js via CDN for interactivity
- Montserrat font (Google Fonts CDN)
- ERB views, import maps, no JS frameworks
- Stimulus infrastructure ready (pinned, eager-loaded, no controllers yet)
- bcrypt password auth + Google OAuth (OmniAuth)
- **Studio engine gem** — `gem "studio", git: "https://github.com/amcritchie/studio.git"`

## JS Modules (importmap)

- `kanban_board` — drag-and-drop task board with optimistic DOM moves, API transitions, toast notifications. Attached to `window.kanbanBoard` for Alpine `x-data` access.
- `dropping_text` — animated text effect on landing page.
- `alex_chat` — Alpine.js `alexChat()` component for AI chat UI. Handles message sending via POST `/chat`, loading states, auto-scroll, basic markdown formatting. Attached to `window.alexChat`.

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
  config.theme_logos = %w[logo-icon.svg icon.svg icon.png studio-logo.svg favicon.png]
end
```

**From the engine:** `Studio::ErrorHandling` concern (in ApplicationController), `ErrorLog` model, `Sluggable` concern, auth controllers (sessions, registrations, omniauth_callbacks, error_logs), error log views, generic login/signup views (overridden by app-branded versions).

**Overridden locally:** `sessions/new.html.erb` and `registrations/new.html.erb` (branded with logo, uses `btn btn-primary`).

**Routes:** `Studio.routes(self)` in `config/routes.rb` draws `/login`, `/signup`, `/logout`, `/sso_continue`, `/sso_login`, `/auth/:provider/callback`, `/auth/failure`, `/error_logs`, `/admin/theme` (GET + PATCH), `/admin/theme/regenerate`.

**SSO Hub Role:** This app is the central auth hub. On login, `set_app_session` stores `sso_*` fields (including `sso_logo`) in the shared session. Admin gear dropdown has "Turf Monster" and "Tax Studio" links pointing to `/sso_login` on each satellite app for one-click SSO. Login page does NOT show "Continue as" (one-way flow — hub only sends, never receives). SSO-created users on satellite apps get `role = "viewer"` via `configure_sso_user`. Requires shared `SECRET_KEY_BASE`.

**Updating:** After changes to the studio repo, run `bundle update studio` here.

## Branding & Theme

- **Theme**: Dynamic — engine-generated CSS custom properties from 7 role colors (see top-level `CLAUDE.md` for full theme docs)
- **Theme config**: Uses all Studio defaults (violet primary `#8E82FE`). No `theme_*` overrides in `studio.rb`.
- **Admin theme page**: `/admin/theme` — color editor + styleguide (from engine)
- **Primary**: `#8E82FE` Violet — CTAs, buttons, links, hovers, form focus. Views use `text-primary`, `bg-primary`, `bg-primary-700` etc. (dynamic Tailwind palette from CSS vars, not hardcoded violet).
- **Success accent**: `#4BAF50` Green (default) — flash notices, success toasts, active status dots
- **Font**: Montserrat (weights 400-900)
- **Logo**: SVG icon (`app/assets/images/logo-icon.svg`) + "McRitchie **Studio**" (Studio in violet)
- **Navbar**: Custom navbar in `application.html.erb` (not engine partial). Sticky, scroll-responsive. `sticky top-0 z-50 bg-page` with Alpine `scrolled` state (triggers at 20px). On scroll: logo shrinks `w-8→w-5`, title `text-2xl→text-base`, padding `py-6→py-2`, adds `shadow-lg border-b border-subtle`. All transitions 300ms. Desktop nav: "Meet the Agents 🦞" link. Mobile sub-navbar with same link + gear/moon icons (logged out only). Logged in: renders `_user_nav` with `show_logout_link: true`. Logged out: gear/moon (desktop only) + "Say Hi 👋" button. Admin gear dropdown has: Dashboard, Agents, Tasks, Turf Monster (SSO), Tax Studio (SSO), Docs, Theme, Toast Test, Schema, Error Logs.
- **Surfaces**: Use `bg-page`, `bg-surface`, `bg-surface-alt`, `bg-inset` — never hardcode `bg-navy-*`
- **Text**: Use `text-heading`, `text-body`, `text-secondary`, `text-muted` — never hardcode `text-white` for headings or `text-gray-*` for body text
- **Borders**: Use `border-subtle`, `border-strong` — never hardcode `border-navy-*`
- **CSS var naming**: `--color-cta` / `--color-cta-hover` for singular CTA color. Full `--color-primary-{50..900}` palette with RGB variants for Tailwind `primary-*` utilities.
- **Tailwind config**: `config/tailwind.config.js` dynamically loads studio engine's shared config (`const studioColors = require(\`${studioPath}/tailwind/studio.tailwind.config.js\`)`). Safelists `primary-{50..900}` × `bg/text/border` × opacity variants to ensure compilation.
- Stage badges: blue=new, yellow=queued, mint=in_progress, green=done, red=failed, gray=archived
- **Button system**: `.btn` base + `.btn-primary` (uses `--color-cta`), `.btn-secondary` (uses `--color-success`), `.btn-outline` (hover uses `--color-cta`), `.btn-danger` (uses `--color-danger`), `.btn-google` (white, hardcoded `color: #374151` for dark mode compat). Size: `.btn-sm`, `.btn-lg`. See top-level `CLAUDE.md` for full reference.

## Models

- **User** — name, email, password_digest, provider, uid, role (admin/viewer), slug. `has_secure_password`, `has_one_attached :avatar`, `from_omniauth`. Helper methods: `avatar_initials` (returns first letters of name parts), `avatar_color` (deterministic hex color from name hash). `from_omniauth` wraps find-or-create in `rescue ActiveRecord::RecordNotUnique` to handle OAuth race conditions (concurrent callbacks for same user).
- **Agent** — name, slug (unique), status (active/paused/inactive), agent_type, title, description, avatar (string, URL path e.g. `/agents/alex.png`), config (jsonb), metadata (jsonb), last_active_at. Has many tasks/activities/usages/skills.
- **Task** — title, slug (unique, random hex, immutable), description, stage (new/queued/in_progress/done/failed/archived), priority (0-2), agent_slug FK, required_skills (jsonb), result (jsonb), error_message, timestamps per stage. Does NOT use Sluggable. **State transitions enforced server-side** via `TRANSITIONS` map and `transition_to!` private method — invalid transitions raise RuntimeError.
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
- **Task transitions** — Enforced server-side. Valid transitions: new→queued, queued→in_progress/failed, in_progress→done/failed, done→archived, failed→archived/queued. Invalid transitions raise RuntimeError. API `task_params` does NOT permit `:stage` — stage changes must go through dedicated transition endpoints (`queue`, `start`, `complete`, `fail_task`, `archive`).
- **Activity slug** — Set via `after_create` as `"activity-#{id}"` (needs id).
- **ErrorLog** (from studio engine) — `ErrorLog.capture!(exception)` with cleaned backtrace. Target/parent set via ActiveRecord setters after creation.
- **Cost** — Stored as `decimal(10,4)` for sub-cent API pricing precision.

## Routes

### HTML (public monitoring, auth-gated mutations)
- `/` — Landing page (hero with Denver bg, about, get in touch with Sprintful + AI chat, acquisition criteria, contact)
- `/dashboard` — Dashboard (agents, task pipeline, activity feed)
- `/chat` — AI chat with Alex agent (Claude Haiku, session-based conversation history). Chat widget partial (`chat/_chat_widget`) also embedded in landing page.
- `/schedule` — Sprintful calendar embed (full-page)
- `/docs` — Agent docs viewer (read-only, markdown rendered)
- `/docs/*path` — Individual doc viewer
- `/agents` — Agent grid
- `/agents/:slug` — Agent detail (tasks, skills, activity)
- `/tasks` — Filterable task list with stage tabs
- `/tasks/new` — Create task (auth required)
- `/tasks/:slug` — Task detail with transition buttons
- `/activities` — Activity feed
- `/usages` — Usage table
- `/toast_test` — Toast notification test page (all variants, server-side flash test)
- `/admin/theme` — Theme editor + styleguide (engine-provided: color editor, logos, tokens, typography, buttons, components)
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
- ChatController#create: uses `create_error_log(e)` directly (no ActiveRecord target — API-only action)

## AI Chat (Alex Agent)

Public-facing chat interface powered by Claude API. Users can chat with an AI Alex persona.

### Architecture
- **ChatController** — `index` renders chat page, `create` accepts JSON `{ message }` and returns `{ response }`. Conversation history stored in `session[:chat_messages]` (last 10 messages).
- **Chat::AlexResponder** — Service using raw `Net::HTTP` to Claude API. Alex McRitchie persona system prompt. Model: `claude-haiku-4-5-20251001`, max tokens: 1024.
- **Chat widget partial** — `chat/_chat_widget.html.erb` accepts `compact:` local (true for landing page card, false for full `/chat` page). Used in both locations.
- **Alpine.js component** — `alexChat()` in `alex_chat.js` handles message state, fetch to `/chat`, loading indicators, auto-scroll, basic markdown rendering.

### Landing Page
- **Hero** — Denver skyline background with Ken Burns pan animation (15s linear), dark overlay for text contrast.
- **Get in Touch section** — Two cards: "Chat Over Video" (Sprintful inline widget embed via `on.sprintful.com`) and "Chat Right Now" (embedded chat widget).
- **Sprintful widget** — Uses official inline widget JS (`app.sprintful.com/widget/v1.js`), not iframe (public URL blocks iframes via X-Frame-Options).

## Seeds

- Admin: `alex@mcritchie.studio` / `password`
- 4 agents with avatars: Alex (orchestrator), Mack (worker), Mason (specialist), Turf Monster (specialist). Avatar images in `public/agents/`. Seed force-updates avatars on existing records.
- 9 skills across data/development/infrastructure/system/domain
- 15 skill assignments
- 8 sample tasks in various stages
- 6 sample activities
- All idempotent via `find_or_create_by!`

## Docs

Agent system documentation at `docs/agents/`:
- `system/` — Architecture, bootstrap, comms protocol, coding standards, credentials (email accounts, 1Password, Solana wallets)
- `agents/{alex,mack,mason,turf_monster}/` — Role and soul docs per agent, each with `avatar.png`
- `shared/MEMORY.md` — Cross-agent shared memory
- **Web viewer**: `/docs` — read-only browser for all agent docs, rendered via Redcarpet gem

## Testing

### Rails Tests
- `bin/rails test` — 34 tests total
- Test fixtures for users, agents, tasks, skills (in `test/fixtures/`)
- Test password: "password" for all fixtures
- `log_in_as(user)` helper for integration tests
- **Model tests**: task transitions (valid/invalid), user (display_name, admin?, avatar_initials, avatar_color, OAuth/`from_omniauth`), slug generation
- **Controller tests**: sessions (login/logout), registrations (signup)

### Playwright E2E Tests
- `npm test` — runs all Playwright tests (13 smoke tests)
- `npm run test:headed` — runs with visible browser
- `npm run test:ui` — opens Playwright UI mode
- **Config**: `playwright.config.js` — Chromium only, port 3000, auto-starts test Rails server
- **Seed**: `e2e/seed.rb` — 1 admin user (alex@test.com / pass), 2 agents, 2 skills, 3 tasks, 2 activities. Idempotent via delete_all.
- **Helper**: `e2e/helpers.js` — `login(page, email, password)`
- **Spec file**: `e2e/smoke.spec.js` — page loads, auth, nav links, theme toggle

## Workflow Preferences

- **Debugging**: STOP on bugs — show the issue and ask before fixing
- **Testing**: Write tests alongside features. **Always run `bin/rails test` before committing** — fix failures before creating the commit. A pre-commit hook enforces this, but proactively run tests after changes rather than waiting for the hook.
- **Database**: Migrate and seed freely without asking
- **Git**: Small frequent commits, push immediately. Run `bin/rails test` before every commit — fix failures before committing.
- **UI**: Style as we build using brand palette
- **Decisions**: Present 2-3 options briefly with a recommendation
- **Refactoring**: Proactively clean up code smells

## Session Protocol

When the user signals end of session, review and refactor ALL CLAUDE.md files to reflect current state.
