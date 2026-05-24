# Routes & Controllers

> **When to read this:** Adding a route, writing a new controller, debugging a write-action error log, or understanding the URL surface.

## HTML Routes (public monitoring, auth-gated mutations)

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
- `/contents/starter_post_x` — POST creates a starter_post_x Content from `/nfl-rosters` button (admin-only). `team_slug` required.
- `/contents/:slug/generate_lineup_assets` — POST captures lineup graphic + uploads PNG/MP4 to S3 + advances to assets stage (admin-only, starter_post_x only)
- `/contents/:slug/post_to_x` — POST programmatically posts the video to X via API (admin-only, starter_post_x only, requires X_API_KEY/SECRET/ACCESS_TOKEN/ACCESS_TOKEN_SECRET)

### Content Pipeline — TikTok workflows

Parallel surface to the X workflow above; entry points create TikTok-flavored Content drafts that flow through the AI agent pipeline.

- `/contents/starter_post_tiktok_offense` — POST creates a TikTok offense-breakdown starter post Content for a team (admin-only). `team_slug` required.
- `/contents/starter_post_tiktok_defense` — POST creates a TikTok defense-breakdown starter post Content for a team (admin-only). `team_slug` required.
- `/contents/:slug/script_agent_step` — POST AI-generate script from hook (hook → script).
- `/contents/:slug/assets_agent_step` — POST AI-generate scene assets from script (script → assets).
- `/contents/:slug/assemble_agent_step` — POST AI-assemble final video from assets (assets → assembly).
- `/contents/:slug/finalize_step` — POST add watermark + finalize the video; stays in `assembly` stage but marks finalized. (FFmpeg watermark step — pending buildpack.)
- `/contents/:slug/metadata_step` — POST AI-generate captions, hashtags, and music suggestions; updates `caption_variants`.
- `/contents/:slug/use_caption_variant` — POST select one caption variant from the generated set; writes to the `captions` field.
- `/contents/:slug/prep_for_tiktok` — POST prepare content for posting (generate caption variants); moves assets → ready-to-post.
- `/contents/:slug/post_to_tiktok` — POST programmatically post the assembled video to TikTok via API (admin-only; requires TikTok OAuth credentials).
- `/contents/:slug/studio_upload_to_tiktok` — POST open TikTok Studio in a browser with the pre-filled video + caption for manual posting (operator-driven fallback).
- `/contents/:slug/mark_posted` — POST record post URL + ID and move Content to `posted` stage. Accepts optional `platform` + `post_url` + `post_id` overrides.
- `/teams/:slug/lineup-graphic` — Public 1200×1500 social-asset render. JS reveals one random photo every 200ms. Used as the screencap target.
- `/nfl` — NFL hub index
- `/nfl-rosters` — Per-team headshot grid: O (12 offense) / D (12 defense) / S (4 special teams: K, P, LS, top returner by `return_grade_pff`) / C (4 coaches: HC, OC, DC, STC). Hover to enlarge image (1.6× → 2.8× scale, with name label below) and swap `src` from 100w to 400w cached variant. Team header links to `/teams/:slug/depth-chart`. Eager-loads `image_caches` via `Roster#pick_starters`. Coaches load via `@coaches_by_team` preload (no headshots → initials circle). Each team header has 3 action buttons: **🆚 Week 1** (links to that team's week-1 game on `/games/:year/week/1/:slug`), **👀 Preview** (opens lineup graphic page in new tab), **🐦 New X Post** (creates a Starter Post X Content draft). Week 1 games are preloaded once in `NflController#rosters` as `@week1_games_by_team`.
- `/nfl-team-grades/:team_slug` — Per-team starting 12-O + 12-D list with proprietary Pass/Run letter-grade badges (A/B/C/D) per starter. Hero gradient from team colors. Bills linked from NFL hub as the example.
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
- `/people/duplicates` — GET admin UI listing detected duplicate Person groups (Levenshtein distance scoring).
- `/people/merge` — GET render the person-merge form (pick keep/merge slugs). `POST /people/merge` → `PeopleController#merge_execute` consolidates contracts, roster spots, coaches, and athlete grades from source → keep person, then deletes source.
- `/activities` — Activity feed
- `/usages` — Usage table
- `/toast_test` — Toast notification test page (all variants, server-side flash test)
- `/admin/theme` — Theme editor + styleguide (engine-provided: color editor, logos, tokens, typography, buttons, components)
- `/error_logs` — Error log index (search with ILIKE, Esc to clear, 500ms loading animation)
- `/error_logs/:slug` — Error log detail (backtrace, target/parent with copy-to-clipboard console commands, JSON)
- `/login`, `/signup`, `/logout` — Auth

## JSON API (`/api/v1/`)

- `GET/POST /api/v1/tasks` — List/create tasks
- `GET/PATCH /api/v1/tasks/:slug` — Read/update task
- `POST /api/v1/tasks/:slug/{queue,start,complete,fail_task}` — Stage transitions
- `GET/PATCH /api/v1/agents/:slug` — Read/update agent
- `GET/POST /api/v1/activities` — List/create activities
- `GET/POST /api/v1/usages` — List/create usage records

## New Controller Checklist

1. Identify write actions (create, update, destroy, state transitions)
2. Wrap each with `rescue_and_log(target:, parent:)` + bang methods inside
3. Add outer `rescue StandardError => e` for response control
4. Ensure model has `to_param` returning `slug` if it appears in URLs
5. Read-only actions are covered by Layer 1 automatically

## Error Handling

Every write action MUST use `rescue_and_log` with target/parent context.

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
