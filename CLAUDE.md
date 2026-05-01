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
- **Env vars**: `RAILS_MASTER_KEY`, `RAILS_SERVE_STATIC_FILES`, `DATABASE_URL` (auto), `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `ANTHROPIC_API_KEY` (for AI chat + content script/metadata agents), `X_BEARER_TOKEN` (for News intake from X/Twitter API), `HIGGSFIELD_API_KEY`, `HIGGSFIELD_API_SECRET` (for content image/video generation via Nano Banana + Kling 3)
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
- bcrypt password auth + Google OAuth (OmniAuth)
- **Studio engine gem** — `gem "studio", git: "https://github.com/amcritchie/studio.git"`

## JS Modules (importmap)

- `kanban_board` — drag-and-drop task board with optimistic DOM moves, API transitions, toast notifications. Race-condition guard (`_pendingMoves`) prevents concurrent API calls for same task. Attached to `window.kanbanBoard` for Alpine `x-data` access.
- `dropping_text` — animated text effect on landing page. Tracks timer IDs and cleans up on `turbo:before-cache` to prevent memory leaks.
- `alex_chat` — Alpine.js `alexChat()` component for AI chat UI. Handles message sending via POST `/chat`, loading states, auto-scroll, basic markdown formatting. HTML-escape happens before markdown transforms (XSS-safe). Attached to `window.alexChat`.
- `depth_chart` — Alpine `depthChart(reorderUrl)` component for `/teams/:slug/depth-chart`. Wires SortableJS per position (drag-reorder, locked rows filter out), calls reorder/toggle_lock endpoints. Attached to `window.depthChart`.

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
- **Navbar**: Custom navbar in `application.html.erb` (not engine partial). Sticky, scroll-responsive. `sticky top-0 z-50 bg-page` with Alpine `scrolled` state (triggers at 20px). On scroll: logo shrinks `w-8→w-5`, title `text-2xl→text-base`, padding `py-6→py-2`, adds `shadow-lg border-b border-subtle`. All transitions 300ms. Desktop nav: "Meet the Agents 🦞" link. Mobile sub-navbar with same link + gear/moon icons (logged out only). Logged in: renders `_user_nav` with `show_logout_link: true`. Logged out: gear/moon (desktop only) + "Say Hi 👋" button. Admin gear dropdown has: Dashboard, Agents, Tasks, News, Turf Monster (SSO), Tax Studio (SSO), Docs, Theme, Toast Test, Schema, Error Logs.
- **Surfaces**: Use `bg-page`, `bg-surface`, `bg-surface-alt`, `bg-inset` — never hardcode `bg-navy-*`
- **Text**: Use `text-heading`, `text-body`, `text-secondary`, `text-muted` — never hardcode `text-white` for headings or `text-gray-*` for body text
- **Borders**: Use `border-subtle`, `border-strong` — never hardcode `border-navy-*`
- **CSS var naming**: `--color-cta` / `--color-cta-hover` for singular CTA color. Full `--color-primary-{50..900}` palette with RGB variants for Tailwind `primary-*` utilities.
- **Tailwind config**: `config/tailwind.config.js` dynamically loads studio engine's shared config (`const studioColors = require(\`${studioPath}/tailwind/studio.tailwind.config.js\`)`). Safelists `primary-{50..900}` × `bg/text/border` × opacity variants to ensure compilation.
- Task stage badges: blue=new, yellow=queued, mint=in_progress, green=done, red=failed, gray=archived
- News stage badges: blue=new, yellow=reviewed, mint=processed, emerald=refined, violet=concluded, gray=archived
- Content stage badges: blue=idea, yellow=hook, mint=script, green=assets, violet=assembly, emerald=posted, gray=reviewed
- **Button system**: `.btn` base + `.btn-primary` (uses `--color-cta`), `.btn-secondary` (uses `--color-success`), `.btn-outline` (hover uses `--color-cta`), `.btn-danger` (uses `--color-danger`), `.btn-google` (white, hardcoded `color: #374151` for dark mode compat). Size: `.btn-sm`, `.btn-lg`. See top-level `CLAUDE.md` for full reference.

## Models

- **User** — name, email, password_digest, provider, uid, role (admin/viewer), slug. `has_secure_password`, `has_one_attached :avatar`, `from_omniauth`. Helper methods: `avatar_initials` (returns first letters of name parts), `avatar_color` (deterministic hex color from name hash). `from_omniauth` wraps find-or-create in `rescue ActiveRecord::RecordNotUnique` to handle OAuth race conditions (concurrent callbacks for same user).
- **Agent** — name, slug (unique), status (active/paused/inactive), agent_type, title, description, avatar (string, URL path e.g. `/agents/alex.png`), config (jsonb), metadata (jsonb), last_active_at. Has many tasks/activities/usages/skills.
- **Task** — title, slug (unique, random hex, immutable), description, stage (new/queued/in_progress/done/failed/archived), priority (0-2), agent_slug FK, required_skills (jsonb), result (jsonb), error_message, timestamps per stage. Does NOT use Sluggable. **State transitions enforced server-side** via `TRANSITIONS` map and `transition_to!` private method — invalid transitions raise RuntimeError.
- **Skill** — name, slug (unique), category, description, config (jsonb). Has many agents through skill_assignments.
- **SkillAssignment** — agent_slug FK, skill_slug FK, proficiency. Join table, no slug.
- **Activity** — agent_slug FK, activity_type, description, task_slug FK, metadata (jsonb), slug (set via after_create).
- **Usage** — agent_slug FK, period_date, period_type, model, tokens_in/out, api_calls, cost (decimal 10,4), tasks_completed/failed, metadata (jsonb), slug.
- **News** — title, slug (unique, random hex `news-*`, immutable), stage (new/reviewed/processed/refined/concluded/archived), url, x_post_id, x_post_url, author, published_at. Pipeline fields populated per stage: reviewed (primary/secondary person/team, primary_action, article_image_url), processed (*_slug fields linking to Person/Team/Contract records), refined (title_short, summary, feeling, feeling_emoji, what_happened), concluded (opinion, callback). Timestamps per stage. Position (integer, 100s increments DESC — highest = top of kanban = processed first by agents). Does NOT use Sluggable. Free movement between stages (like Tasks). Agent assignments: new=intake, reviewed=Mason, processed=Mack, refined=Alex, concluded=Turf Monster, archived=Alex.
- **Content** — title, slug (unique, random hex `content-*`, immutable), stage (idea/hook/script/assets/assembly/posted/reviewed), description, source_type, source_news_slug. Pipeline fields per stage: hook (hook_image_url, hook_ideas JSONB, selected_hook_index), script (script_text, duration_seconds, scenes JSONB), assets (scene_assets JSONB), assembly (final_video_url, music_track, text_overlays JSONB, logo_overlay), posted (platform, post_url, post_id, posted_at), reviewed (views, likes, comments_count, shares, review_notes). Video production fields: reference_video_url, reference_video_start/end (seconds), rival_team_slug (FK → Team), captions (text), hashtags (JSONB), music_suggestions (JSONB). `belongs_to :rival_team` (Team via slug FK, optional). `belongs_to :source_news` (optional, via slug FK). Position (integer, 100s increments DESC). Stage timestamps set on before_save. Transition methods: `hook!`, `script!`, `assets!`, `assemble!`, `post!`, `review!`. Does NOT use Sluggable.
- **Team** — name, short_name, slug (unique), location, emoji, color_primary, color_secondary, color_text_light (boolean — true when primary color needs dark text), sport (`"football"`/`"soccer"`), league (`"nfl"`/`"ncaa"`/`"fifa"`), conference (AFC/NFC, SEC/Big Ten, Group A-L), division (East/North/South/West — NFL only), rivals (JSONB array of team slugs). `include Sluggable`, `name_slug` = `name.parameterize`. Has many contracts/people. Scopes: `nfl`, `ncaa`, `fifa`, `football`, `soccer`. Seeded with 32 NFL + 71 NCAA + 48 FIFA = 151 total. NFL teams seeded with 3-4 rivals each (division + historic).
- **Person** — first_name, last_name, slug (unique), athlete (boolean), aliases (JSONB array, default `[]` — alternate name spellings). `include Sluggable`, `name_slug` = full name parameterized. Has many contracts/teams. `has_one :athlete_profile` (Athlete model via `person_slug`). Helper: `full_name`. Created automatically by `News::Process` when processing news articles.
- **Athlete** — person_slug (unique FK to Person), sport (`"football"`/`"soccer"`), position (QB, WR, EDGE, FW, MF, GK, etc.), draft_year, draft_round, draft_pick. Appearance fields: skin_tone (light/medium/dark), hair_description, build, height_inches, weight_lbs. **Cross-ref IDs** (each unique-indexed): `gsis_id` (NFL canonical anchor), `espn_id`, `pff_id` (int), `otc_id`, `pfr_id`, `nflverse_id`. **Team association**: `team_slug` (string, indexed) + `belongs_to :team, optional: true`. Updated by Spotrac sync, ESPN scrape, and on Contract create — never written directly. `espn_headshot_url` is always derived from `espn_id` (`a.espncdn.com/i/headshots/nfl/players/full/{id}.png`), never the nflverse `headshot_url` column which is 12× larger NFL.com static. `include Sluggable`, `name_slug` = `"#{person_slug}-athlete"`. `belongs_to :person` via slug FK. `has_many :image_caches, as: :owner, class_name: "ImageCache"` (explicit class_name — Rails singularizes wrong otherwise). `#headshot_url(width: 400)` looks up the cached variant via `image_caches`; eager-load with `includes(:image_caches)` to avoid N+1. **Note:** Person has a boolean `athlete` column AND `has_one :athlete_profile` — the association is named `athlete_profile` (not `athlete`) to avoid collision with the boolean column.
- **Contract** — person_slug, team_slug, slug (unique), expires_at (date — college contracts expire April 1, 2026), annual_value_cents (bigint — NFL star salaries in cents, e.g. $55M = 5_500_000_000), position. `include Sluggable`, `name_slug` = `"#{person_slug}-#{team_slug}"`. Join table linking Person ↔ Team via slug FKs. Unique constraint on `[person_slug, team_slug]`. Helpers: `active?` (no expiry or future), `expired?` (past expiry). Created automatically by `News::Process`.
- **DepthChart** — team_slug (unique), slug. `include Sluggable`, `name_slug` = `"#{team_slug}-depth"`. One per NFL team, has many DepthChartEntry. Canonical source for "who plays where + depth ordering" — drives `Roster#offense_starting_12` / `defense_starting_12` and `/nfl-rosters`. Manageable via `/teams/:slug/depth-chart` UI.
- **DepthChartEntry** — depth_chart_slug (FK), person_slug (FK to Person), position (canonical bucket like EDGE/DT/LB after `PositionConcern.normalize_position(_, source: :espn)`), `formation_slot` (raw ESPN label like WLB/LDE/NT/NB/LCB — preserved verbatim, drives the picker), side (offense/defense/special_teams), depth (1..N within position), locked (bool). Unique on `[depth_chart_slug, person_slug, position]`. Locked rows are skipped by the seed re-rank, the ESPN scraper move/dedup logic, AND the position reconciler — manual overrides survive all refreshes.
- **ErrorLog** — message, inspect, backtrace (JSON), polymorphic target/parent, target_name, parent_name, slug.

## Database Standards

- Every table gets `timestamps` (`created_at`, `updated_at`) — no exceptions

## Key Patterns

- **Slug-based FKs** — All foreign keys use slug strings (e.g. `agent_slug`), not integer IDs. Associations: `foreign_key: :agent_slug, primary_key: :slug`.
- **Sluggable concern** (from studio engine) — `before_save :set_slug` via `name_slug` method. Used by User, Agent, Skill, Usage, Team, Person, Contract, Athlete.
- **Task slug** — Immutable random hex generated once on create via `before_validation`. Does NOT use Sluggable.
- **Task transitions** — Enforced server-side. Valid transitions: new→queued, queued→in_progress/failed, in_progress→done/failed, done→archived, failed→archived/queued. Invalid transitions raise RuntimeError. API `task_params` does NOT permit `:stage` — stage changes must go through dedicated transition endpoints (`queue`, `start`, `complete`, `fail_task`, `archive`).
- **Position ordering** — Both News and Content use position integers in 100-increments, ordered DESC (highest = top of kanban = processed first by agents). Initial position set on create. Position updated when stage changes. Reorder via POST `/news/reorder` or `/contents/reorder`.
- **News slug** — Immutable random hex (`news-*`) generated once on create via `before_validation`. Does NOT use Sluggable. Free movement between stages via PATCH JSON (stage permitted in `news_params`). Transition methods: `review!`, `process_news!`, `refine!`, `conclude!`, `archive!`.
- **Content slug** — Immutable random hex (`content-*`) generated once on create via `before_validation`. Does NOT use Sluggable. Free movement between stages. Transition methods: `hook!`, `script!`, `assets!`, `assemble!`, `post!`, `review!`.
- **News services** — `app/services/news/` contains 5 service classes + 3 AI agents (reopening the `News` class, not a module). Services take a News record, accept a fields hash, update fields, and advance the stage. AI agents call Claude API to generate the fields, then delegate to the corresponding service.
  - `News::Intake` — Fetches latest Adam Schefter tweets from X API v2. Requires `X_BEARER_TOKEN` in `.env`. Creates News with `stage: "new"`. Deduplicates by `x_post_id`. Rake: `bin/rails news:intake`.
  - `News::Review` (Mason) — Sets primary/secondary person/team/action + article_image_url → `review!`
  - `News::ReviewAgent` — Claude Haiku extracts people/teams/action from tweet text → delegates to `News::Review`. Rake: `bin/rails news:review`.
  - `News::Process` (Mack) — Generates slugs via `parameterize`, find-or-creates Person/Team records, creates Contract associations → `process_news!`. Tracks `created_records` array reporting whether each Person/Team was `created`, `found`, or `not_found`. Rake: `bin/rails news:process` (outputs `[+]` created, `[=]` found, `[?]` not_found).
  - `News::Refine` (Alex) — Sets title_short (3-5 words), summary, feeling, feeling_emoji, what_happened → `refine!`
  - `News::RefineAgent` — Claude Haiku generates refined summary fields from tweet + review context → delegates to `News::Refine`. Rake: `bin/rails news:refine`.
  - `News::Conclude` (Turf Monster) — Sets opinion, callback → `conclude!`
  - `News::ConcludeAgent` — Claude Haiku generates editorial opinion + callback action → delegates to `News::Conclude`. Rake: `bin/rails news:conclude`.
  - **Full pipeline**: `bin/rails news:intake news:review news:process news:refine news:conclude`
  - **SLUG= override**: All rake tasks accept `SLUG=news-abc123` to target a specific article instead of picking the next one.
  - **Agent ordering**: All `*_latest` methods use `position: :desc` to pick the top-of-kanban (highest position) article first.
- **NFL data ingest pipeline** — three layered services, each authoritative for one slice of state. Run via `/nfl-rebuild` (full) or `/nfl-refresh` (weekly). Layers:
  1. **`Nflverse::SeedPlayers`** (`app/services/nflverse/seed_players.rb`, rake `nfl:players_seed`) — identity backbone. Pulls `players.csv` from nflverse-data GitHub release (~24k rows, default filter is `last_season>=2024` only — no status filter so UFA/RES/PUP veterans like Hunt/Harris/Waller are included). Upserts Person + Athlete with all five cross-ref IDs (`gsis_id`, `espn_id`, `pff_id`, `otc_id`, `pfr_id`, `nflverse_id`). Lookup priority is `gsis_id` (anchor) → `pff_id` → `otc_id` → `espn_id` → `pfr_id` → `person_slug` (name match) → create. Sets `Athlete.team_slug` from `latest_team` and caches ESPN headshots to S3 inline (idempotent, skipped without AWS creds). The `team_slug` here is provisional — Spotrac and ESPN authoritatively overwrite below. Optional env: `STATUS=ACT` to re-narrow, `MIN_SEASON=2025` to scope tighter.
  2. **`Spotrac::SyncContracts`** (`app/services/spotrac/sync_contracts.rb`, rake `nfl:salaries_sync`) — salary overlay. Reads `db/seeds/data/spotrac_contracts.json` (committed, ~2,500 entries), matches Athletes by `otc_id` then name fallback, upserts active Contracts with `annual_value_cents` and `expires_at` (end_year → March 15 of that year). Updates `Athlete.team_slug` per the contract-update rule.
  3. **`Espn::ScrapeDepthCharts`** (`app/services/espn/scrape_depth_charts.rb`, rake `espn:scrape_depth_charts`) — current-roster + depth truth. Hits `https://www.espn.com/nfl/team/depth/_/name/{abbrev}` per team (data embedded in `window['__espnfitt__']`). Auto-creates DepthChart shells and Contracts for ESPN-listed players we don't have yet (UDFAs, mid-season call-ups). When a player has shifted teams, expires the old active Contract and creates the new one. Updates `Athlete.team_slug`. Stores both `position` (collapsed canonical) AND `formation_slot` (raw ESPN label) on each DepthChartEntry. Locked entries are never moved. Behaviors of note:
     - **Row-grouped flatten** — multi-row position groups (3 WR rows for WR1/WR2/WR3 chains) round-robin starters together: row1[0], row2[0], row3[0], then row1[1], etc. Drives WR1/WR2/WR3 = starter from each row.
     - **Position reconciliation** — front-7 entries whose `position` (from ESPN_MAP) disagrees with `athlete.position` get moved (Crosby OLB→EDGE, Heyward EDGE→DT). Reconciliation is RECONCILE_FRONT7-scoped (D-line + LB axis); CB↔S is intentionally NOT reconciled (slot/big-nickel fluidity is real).
     - **Stale-entry pruning** — when post-merge data leaves a player with two entries on the same chart at different positions, apply_row keeps the entry already at the target position and drops the rest.
     - **Verbatim ESPN order** — apply_row preserves ESPN's listed order for new vs existing entries. Brand-new players ESPN promotes above an existing one get the higher slot (Will Campbell at LT1 over Hudson, post-fix).
     - **Partial-response guard** — if ESPN returns < 3 sides for a team (e.g. only "Base 4-3 D" with no offense or special teams — Lions hit this on 2026-05-01), skip the team entirely instead of half-overwriting. teams_partial counter on stats hash.
     - **`espn_id` backfill on name match** — when ESPN places a player who was found via name fallback (not espn_id lookup), persist the `espn_id` from ESPN's href on the Athlete + derive `espn_headshot_url`. Pre-fix, those athletes had a depth chart entry but no espn_id, so `nfl:upload_headshots` couldn't cache their headshot. Backfilled ~110 athletes per scrape with this added.

- **PFF grade pipeline** — `db/seeds/data/pff/*.csv` (committed) → `db/seeds/29_pff_grades.rb` → `Pff::ImportCsv` (`app/services/pff/import_csv.rb`). Detects stat_type from filename. Each stat_type has a `POSITION_FILTER` whitelist so only relevant positions get grades written. For blocking CSVs without `grades_offense`, derives `overall_grade` as the avg of `pass_block_grade` + `run_block_grade`; for defensive sub-CSVs without `grades_defense`, derives from coverage/pass_rush/rush_defense. Position normalization uses `source: :pff`. After PFF runs, `30_athlete_grades.rb` writes a flat 50.0 placeholder for non-PFF active athletes so ranking pages have something to sort against. Drop new CSVs into the dir and re-seed; idempotent via `find_or_initialize_by`. Currently imported: 11 stat types.

- **12-slot starter layout** — `Roster#offense_starting_12` and `Roster#defense_starting_12` return ordered Hashes with one PickedSpot per slot:
  - **Offense**: `:qb, :rb, :wr1, :wr2, :wr3, :te, :flex, :lt, :lg, :c, :rg, :rt`. Flex = highest `offense_grade` among (RB depth=2, WR depth=4, TE depth=2). RB pool sorted with `RB_PRIORITY = {RB: 0, HB: 1, FB: 2}` so true RBs always beat FBs at the same depth.
  - **OL slots** (`pick_ol_slot`) prefer the lowest-depth entry matching the slot's specific position (LT/LG/C/RG/RT), then fall back to generic OT/OG. Critical: uses `min_by(&:depth)`, not `.detect` — first-by-depth, not first-by-insertion-order. Pre-fix, seed-31 entries (older ids) won over ESPN-set depth=1 entries (Saints LT showed Landon Young at LT2 instead of Kelvin Banks Jr. at LT1).
  - **Defense**: `:edge1, :edge2, :dl1, :dl2, :dl_flex, :lb1, :lb2, :ss, :fs, :cb1, :cb2, :flex` (the 12th = nickel). Picker uses scheme-agnostic formation map + athlete.position disambiguation (see below).
  - **Special teams**: `:k, :p, :ls, :returner` (Roster#special_teams_starting_4).

- **Defensive picker (scheme-agnostic)** — `pick_defense_by_formation` uses `PositionConcern::FORMATION_GROUPS` (formation_slot → list of eligible display groups, e.g. `LDE => [:edge, :dl]`) plus `GROUP_ATHLETE_POSITIONS` (display group → matching athlete.position values) to bucket each entry into ONE display group. Per group: take the lowest-depth entry per formation_slot (the formation's "starter"), sort by the slot's grade criterion, assign top N. Solves the 3-4 vs 4-3 ambiguity without scheme detection: 3-4 LDE/RDE (interior) → DL pool because athlete.position=DT; 4-3 LDE/RDE (edge) → EDGE pool because athlete.position=EDGE. Same map handles both. Pool-based fallback used when no formation_slot data exists (plain `db:seed` without ESPN).

- **Depth chart pipeline** — `Roster#offense_starting_12` and `Roster#defense_starting_12` read `DepthChartEntry` rows at runtime. Two ways entries land:
  - Live: `bin/rails espn:scrape_depth_charts` (preferred — current week's depth per ESPN, populates `formation_slot`).
  - Fallback: `db/seeds/31_depth_charts.rb` ranks by `overall_grade DESC, salary DESC` from active contracts; sets `position` only (no `formation_slot`). Used during plain `db:seed` when ESPN isn't run.
  - UI edits via `/teams/:slug/depth-chart` (drag-reorder, lock toggle) flow immediately to `/nfl-rosters`. Locked entries are skipped by all refresh paths.

- **Slot label rendering** — `LineupLabelsHelper.offense_slot_label(slot, pick)` and `defense_slot_label(slot, pick)` produce display badges. Depth digits dropped (depth implied by left-to-right slot order: WR1/WR2/WR3 all show "WR", E1/E2 show "EG", etc.). Flex slots derive their label from `pick.position` so a TE2 in offense Flex shows "TE", a slot CB in defensive Flex shows "CB". Used by both `/nfl-rosters` and `/teams/:slug/depth-chart`.

- **Position normalization** — `PositionConcern` (`app/models/concerns/position_concern.rb`) holds canonical position lists, per-source mapping tables (`ESPN_MAP`, `PFF_MAP`, `NFLVERSE_MAP`, `SPOTRAC_MAP`, `GENERAL_MAP`), AND the `FORMATION_GROUPS` / `GROUP_ATHLETE_POSITIONS` maps used by the defensive picker. Callers pass `source:` to dispatch: `PositionConcern.normalize_position("LDE", source: :espn) # => "EDGE"`. Falls back to `GENERAL_MAP` when source is omitted.

- **Athlete cross-ref IDs** — `Athlete` has columns for every external system's player ID: `gsis_id` (NFL canonical), `espn_id`, `pff_id`, `otc_id` (Spotrac/OverTheCap), `pfr_id` (Pro-Football-Reference), `nflverse_id`. `Nflverse::SeedPlayers` populates them all from one CSV row. Importers use **ID-first lookup** (`gsis_id → pff_id → otc_id → espn_id → pfr_id`) before any name match. This eliminated the 122-of-122 split-record collision class where suffix-stripped duplicates ("Will Anderson" vs "Will Anderson Jr.") competed for the same canonical IDs. nflverse's `pff_position` column is preferred over the generic `position` column when present — disambiguates 3-4 OLBs (Watt/Crosby tagged "OLB" in `position` but "ED" in `pff_position`) and interior linemen mislabeled as DE in 3-4 schemes (J.J. Watt: position=DE, pff_position=DI).

- **Duplicate-Person merge** — `Athletes::MergeDuplicates` (`app/services/athletes/merge_duplicates.rb`, rake `nfl:merge_duplicate_athletes`) finds Persons via two patterns: suffix variants (`will-anderson` ↔ `will-anderson-jr`) and same-name siblings with distinct slugs (case-insensitive first+last match where one has IDs and one doesn't). Moves contracts, depth_chart_entries, roster_spots, grades, pff_stats, image_caches from duplicate to canonical (dropping conflicts in favor of the canonical row), then deletes duplicate Athlete + Person. Defaults to `DRY_RUN=1`; pass `DRY_RUN=0` to commit. Wired into `/nfl-rebuild` Step 3.5 (after `nfl:players_seed` + before ESPN scrape).

- **Coach headshot pipeline** — `nfl:link_coach_headshots` (ESPN v2 coaches API for HCs) + `nfl:link_coach_headshots_from_team_sites` (NFL.com per-team scrape from `Team.coaches_url`) populate `Coach.espn_headshot_url`. `nfl:upload_coach_headshots` caches variants to S3 with `cache_control: immutable, max-age=1y`. **Stale-cache invalidation**: when `coach.espn_headshot_url` changes (e.g., second pass overwrites with NFL.com URL after first pass set ESPN URL), upload detects the mismatch (`source_url` on existing variants ≠ current URL, or sources differ across variants), wipes the rows, and re-uploads from current source. Required because `Studio::ImageCache.cache!` is idempotent — wouldn't otherwise refresh. Fixed McVay's mismatched B&W 100w + color 400w variants. Reports per-team gap of still-missing coaches at end of upload.
- **Content services** — `app/services/content/` contains 6 manual service classes + 5 AI agents (reopening the `Content` class). Manual services accept pre-computed fields and advance stage. AI agents call external APIs then delegate to the manual services.
  - `Content::Hook` — idea → hook (hook_image_url, hook_ideas, selected_hook_index)
  - `Content::Script` — hook → script (script_text, duration_seconds, scenes)
  - `Content::Assets` — script → assets (scene_assets)
  - `Content::Assemble` — assets → assembly (final_video_url, music_track, text_overlays, logo_overlay)
  - `Content::Post` — assembly → posted (platform, post_url, post_id, posted_at)
  - `Content::Review` — posted → reviewed (views, likes, comments_count, shares, review_notes)
  - `Content::ScriptAgent` — Claude Opus generates script/scenes from player context → delegates to `Content::Script`
  - `Content::AssetsAgent` — Higgsfield (Nano Banana) generates scene images → delegates to `Content::Assets`
  - `Content::AssembleAgent` — Higgsfield (Kling 3) generates video from scene images → delegates to `Content::Assemble`
  - `Content::Finalize` — FFmpeg watermark overlay (stub pending buildpack). Updates logo_overlay.
  - `Content::MetadataAgent` — Claude Haiku generates TikTok captions, hashtags, music suggestions. Can run at any stage.
  - `Higgsfield::Client` — Shared HTTP client (`app/services/higgsfield/client.rb`). Auth via `hf-api-key`/`hf-secret` headers. Submit + poll pattern with 5-min timeout.
  - Rake tasks: `content:hook`, `content:script`, `content:assets`, `content:assemble`, `content:post`, `content:review` (manual). `content:script_agent`, `content:assets_agent`, `content:assemble_agent`, `content:finalize`, `content:metadata` (AI). `content:generate SLUG=xxx` (full pipeline). All support `SLUG=` override.
  - **Feature status: ON ICE** — Services are built and wired up but not yet tested end-to-end with real API calls.
- **News → Content bridge** — `NewsController#create_content` creates a Content (stage: idea) linked to a concluded News article via `source_news_slug`. Button on News show page when stage == "concluded".
- **Pipeline progression** — Shared partial `app/views/shared/_pipeline_progression.html.erb` shows unified 12-step pipeline across News (1-6) and Content (7-12), with archived as a side step from concluded. Accepts `highlight:` param ("news" or "content") to dim the non-active pipeline. Rendered on both index pages.
- **Kanban column focus** — Click column header to expand that column full-width (hides others). Click again to unfocus. Alpine `focusedStage` state with `toggleFocus()` method. Both News and Content boards.
- **People search** — `PeopleController#search` JSON endpoint with ILIKE matching on first_name, last_name, slug, and aliases. Used by News edit sidebar for verifying Person records during news processing.
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
- `/news` — News pipeline Kanban board (6 columns: new→reviewed→processed→refined→concluded→archived). SortableJS drag-and-drop. Inline `newsBoard()` Alpine function. Column focus: click header to expand single column full-width (hides others, click again to unfocus).
- `/news/new` — Create news article (admin required)
- `/news/:slug` — News detail (two-column: content + sidebar with timeline). Shows green/red dots next to slug fields indicating whether Person/Team records exist.
- `/news/:slug/edit` — Edit news article (admin required). Two-column layout: form (2/3) + People Search sidebar (1/3) with live search, aliases display, team badges.
- `/news/workflow` — News pipeline documentation page (read-only)
- `/news/reorder` — POST reorder within column
- `/news/:slug/archive` — POST archive news item
- `/news/:slug/review` — POST AI-review (new→reviewed, admin-only)
- `/news/:slug/process_step` — POST auto-generate slugs + create Person/Team/Contract records (reviewed→processed, admin-only)
- `/news/:slug/refine` — POST AI-generate summary/feeling (processed→refined, admin-only)
- `/news/:slug/conclude` — POST AI-generate opinion/callback (refined→concluded, admin-only)
- `/news/:slug/create_content` — POST create Content idea from concluded News (admin-only)
- `/contents` — Content pipeline Kanban board (7 columns: idea→hook→script→assets→assembly→posted→reviewed). SortableJS drag-and-drop. Column focus same as News.
- `/contents/new` — Create content idea (admin required)
- `/contents/:slug` — Content detail (two-column: content + sidebar with timeline/actions)
- `/contents/:slug/edit` — Edit content (admin required)
- `/contents/reorder` — POST reorder within column
- `/contents/:slug/{hook,script,assets,assemble,post,review}_step` — POST manual stage transition actions (admin-only)
- `/contents/:slug/{script_agent,assets_agent,assemble_agent,finalize,metadata}_step` — POST AI agent actions (admin-only)
- `/nfl` — NFL hub index
- `/nfl-rosters` — Per-team headshot grid: O (12 offense) / D (12 defense) / S (4 special teams: K, P, LS, top returner by `return_grade`) / C (4 coaches: HC, OC, DC, STC). Hover to enlarge image (1.6× → 2.8× scale, with name label below) and swap `src` from 100w to 400w cached variant. Team header links to `/teams/:slug/depth-chart`. Eager-loads `image_caches` via `Roster#pick_starters`. Coaches load via `@coaches_by_team` preload (no headshots → initials circle).
- `/teams/:slug/depth-chart` — Manage a team's full DepthChart. Positions grouped by side (offense/defense/special teams). Drag-handle reorders depth within a position via SortableJS; lock toggle (🔓/🔒) per entry — locked rows are skipped by seed re-rank and ESPN scraper. JS in `app/javascript/depth_chart.js` (importmap-pinned). Endpoints: `POST /teams/:slug/depth-chart/reorder` and `POST /depth_chart_entries/:id/toggle_lock`.
- `/nfl-quarterback-rankings`, `/nfl-offensive-line-rankings`, `/nfl-receiving-rankings`, `/nfl-rushing-rankings`, `/nfl-defense-rankings`, `/nfl-pass-rush-rankings`, `/nfl-coverage-rankings` — Position ranking pages (sortable, searchable)
- `/nfl-pass-first-rankings` — Coach pass-first/pass-heavy rankings
- `/nfl-team-rankings/:id` — Team unit rankings (offense + defense breakdown)
- `/nfl-player-impact/:player_id/to/:team_id` — Player impact simulator (lineup comparison + ranking deltas)
- `/nfl-player-impact/:player_id/to/:team_id/confirm` — POST confirm draft pick (admin-only). Creates/converts contract to `draft_pick`, expires college contracts, recomputes rankings, creates News at refined stage. Checkbox: bench_rookie skips ranking recompute.
- `/nfl-prospects` — Draft prospects (2025 draft_pick / 2026 mock_pick, sortable)
- `/nfl-coaches` — NFL coaches list (sortable, searchable)
- `/nfl-contracts` — Contract index
- `/people` — Card grid of all Person records with sport filter + JS search. Each card shows Athlete headshot (400w cached variant via `Athlete#headshot_url`) or initials fallback if no cached image. Eager-loads `athlete_profile: :image_caches`.
- `/people/search` — GET JSON people search (ILIKE on first_name, last_name, slug, aliases). Used by News edit sidebar.
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
- HTML NewsController: all write actions (create, update, destroy, archive, reorder, review, process_step, refine, conclude, create_content) wrapped with `target: @news`
- HTML ContentsController: all write actions (create, update, destroy, reorder, hook_step, script_step, assets_step, assemble_step, post_step, review_step) wrapped with `target: @content`
- HTML TasksController: all 8 write actions wrapped with `target: @task`
- API TasksController: all 8 write actions wrapped with `target: task`
- API AgentsController#update, ActivitiesController#create, UsagesController#create: all wrapped
- RankingsController#confirm_draft_pick: wrapped with `target: contract`
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

Seeds are split into `db/seeds/` directory, loaded in order by `db/seeds.rb`:

Each file only depends on files above it. Teams → Seasons → People → Grades → Rosters → Games → Demo data.

| Phase | File | Contents |
|-------|------|----------|
| 1. Infrastructure | `01_users.rb` | 4 admin users |
| | `02_agents.rb` | 4 agents with avatars |
| | `03_skills.rb` | 9 skills + 15 assignments |
| 2. Leagues | `10_teams_nfl.rb` | 32 NFL teams (sport/league/conference/division) |
| | `11_teams_ncaa.rb` | 71 NCAA teams (schools from 2025 draft picks) |
| | `12_teams_fifa.rb` | 48 FIFA World Cup 2026 teams (sport/league/group) |
| | `15_seasons.rb` | 3 seasons (1 active) |
| | `16_slates.rb` | 29 slates across seasons |
| 3. People | `20_coaches_nfl.rb` | 128 NFL coaches (HC + coordinators) |
| | `21_coaches_fifa.rb` | 48 FIFA coaches (one per team) |
| | `22_nfl_contracts.rb` | One-liner that calls `Spotrac::SyncContracts.new.call`. Layers ~2,420 active contracts (Person + Athlete + Contract w/ `annual_value_cents`) on top of nflverse identity records. Idempotent. Standalone task: `bin/rails nfl:salaries_sync`. |
| | `23_nfl_prospects.rb` | 102 draft prospects + 1 hypothetical → Person + Athlete + college Contract + NFL draft_pick Contract |
| | `25_fifa_players.rb` | 48 FIFA stars → Person + Athlete + Contract (`contract_type: "active"`) |
| 4. Evaluation | `29_pff_grades.rb` | Imports `db/seeds/data/pff/*.csv` via `Pff::ImportCsv`. 11 stat types, position-filtered. ~570 graded athletes when all CSVs present. Matches by `pff_id` when nflverse has populated it; falls back to name match. |
| | `30_athlete_grades.rb` | Synthetic fallback. Non-PFF NFL athletes get a flat 50.0 placeholder so ranking pages have a value to sort against; prospects keep tier-based ranges (JSONB `grade_ranges`) since draft slot is the only signal. Depth chart ordering is no longer driven by these — ESPN does that. |
| | `31_depth_charts.rb` | One DepthChart per NFL team, one DepthChartEntry per (person, position). Grade-rank fallback used during plain `db:seed`; live updates come from `bin/rails espn:scrape_depth_charts` (preferred). Locked entries hold position+depth across re-seeds AND ESPN scrapes. |
| | `31_rosters.rb` | 64 rosters, ~5000 roster spots. Depth denormalized from DepthChart. |
| | `32_headshot_links.rb` | DB-only. Coach `espn_headshot_url` discovery: HCs from ESPN's coaches API + all 4 roles scraped from each team's NFL.com page (URL stored on `Team.coaches_url`, seeded from `NFL_TEAM_DOMAINS` in `10_teams_nfl.rb`). Scraper falls back between `/team/coaches/` and `/team/coaches-roster/` (Bucs and Titans use the latter). Athlete URLs come from `nfl:players_seed` (nflverse master CSV), not this seed. |
| 5. Schedule | `40_games.rb` | Games across slates |
| 6. Demo Content | `50_news.rb` | 5 world cup articles + 34 NFL Draft tweets (@AdamSchefter) |
| | `51_contents.rb` | 4 content items across stages |
| | `52_tasks.rb` | 8 sample tasks |
| | `53_activities.rb` | 6 sample activities |

**Totals:** 151 teams, ~2741 people, ~2566 athletes, ~2740 contracts (103 college, ~2535 active, 102 draft). All idempotent via `find_or_create_by!`.

### Full rebuild vs plain seed

For a house-burned-down recovery use the `/nfl-rebuild` skill (`.claude/skills/nfl-rebuild/SKILL.md`) — it runs `db:reset`, then `db:seed`, then `nfl:players_seed` (nflverse master CSV identity backbone with cross-ref IDs + S3 headshot caching), then `espn:scrape_depth_charts` (ESPN-driven roster + depth chart truth). The plain `db:seed` alone gets you a working dev DB with the Spotrac star roster but without the long-tail of backups/UDFAs and without the ESPN-current depth chart.

For weekly in-season refresh use `/nfl-refresh` — non-destructive, just nflverse delta + ESPN scrape.

- Admin: `alex@mcritchie.studio` / `password`
- NFL Draft tweets: oldest→newest in array, `.reverse` before seeding so oldest = top of kanban. Deduped by `x_post_id`.
- College contracts expire `2026-04-01`. NFL star contracts have `annual_value_cents` (bigint).
- `contract_type` set correctly at creation (no backfill hack needed).

## Docs

Agent system documentation at `docs/agents/`:
- `system/` — Architecture, bootstrap, comms protocol, coding standards, credentials (email accounts, 1Password, Solana wallets), news-pipeline (services, onboarding checklist, X API setup)
- `agents/{alex,mack,mason,turf_monster}/` — Role and soul docs per agent, each with `avatar.png`
- `shared/MEMORY.md` — Cross-agent shared memory
- **Web viewer**: `/docs` — read-only browser for all agent docs, rendered via Redcarpet gem

## Testing

### Rails Tests
- `bin/rails test` — 418 runs, ~1080 assertions, 5 skips (legacy grade-based ranking tests obsoleted by manual DepthChart)
- Test fixtures for users, agents, tasks, news, contents, skills, teams, people, contracts, athletes (in `test/fixtures/`)
- Test password: "password" for all fixtures
- `log_in_as(user)` helper for integration tests
- **Model tests**: task transitions (valid/invalid), news transitions/slug/position/validations, content slug/stages/position/source_news, user (display_name, admin?, avatar_initials, avatar_color, OAuth/`from_omniauth`), slug generation, team/person/contract associations and validations, athlete slug/validations/person association
- **Controller tests**: sessions (login/logout), registrations (signup), news (CRUD, stage moves, reorder, refine, conclude, create_content, auth enforcement), contents (CRUD, step actions, stage guards, auth enforcement), tasks (CRUD, stage moves, reorder, auth enforcement), rankings (all position pages, sorting, search, team unit, player impact, confirm draft pick with auth/mock conversion/bench rookie/college expiry)

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
