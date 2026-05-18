# McRitchie Studio

Task management and orchestration hub for the McRitchie AI agent system. Four agents (Alex, Mack, Mason, Turf Monster) run tasks, track usage, and log activities through a web dashboard and JSON API.

**Live**: https://app.mcritchie.studio

McRitchie Studio is the **flagship app** of a 5-repo ecosystem ([turf_monster](https://github.com/amcritchie/turf_monster), [studio](https://github.com/amcritchie/studio), [solana_studio](https://github.com/amcritchie/solana_studio), [turf_vault](https://github.com/amcritchie/turf_vault)). Clone this repo first; it carries the scripts that bootstrap everything else.

> **New here?** Read [`docs/ECOSYSTEM.md`](docs/ECOSYSTEM.md) first — it's the canonical 2-minute orientation surface for the whole 5-repo ecosystem.

---

## Fresh-Mac ecosystem recovery (the canonical path)

Use this when standing up a brand new machine, or anytime you want to confirm "everything still works." Idempotent — safe to re-run.

**One-time prereqs** (NOT auto-installed):
- macOS with Xcode Command Line Tools (`xcode-select --install`)
- [Homebrew](https://brew.sh)
- A 1Password service account token with **read** access to the `agents` vault (account `alex@mcritchie.studio`). Generate at https://start.1password.com → Developer Tools → Service Accounts.

```bash
# 1. Clone the flagship — every other repo + script lives downstream of this one.
git clone https://github.com/amcritchie/mcritchie_studio.git ~/projects/mcritchie_studio
cd ~/projects/mcritchie_studio

# 2. First pass — installs every brew package (incl. 1Password CLI), Rust, Solana,
#    Anchor, etc. Bails at Phase 4 once it needs your 1Password service token.
bin/ecosystem-build

# 3. Copy your 1Password service account token (ops_...) to clipboard, then:
bin/setup-1pass-token

# 4. Second pass — picks up at Phase 4, pulls Heroku key + .env for the flagship,
#    clones the other 4 repos in Phase 5, bundles + DBs + Anchor + Playwright,
#    and bounces both Rails servers. On the first time through this fails
#    halfway because Phase 4 ran BEFORE the siblings existed on disk, so their
#    .env files weren't populated — see step 5.
bin/ecosystem-build

# 5. Third pass (cold-boot only) — Phase 4 now sees the freshly-cloned siblings
#    and writes their .env files. Phase 6 completes db:seed for all apps. You
#    end at a known-good steady state.
bin/ecosystem-build
```

~25–30 min wall time on a fresh machine. On every later run it's ~30 s — the script just walks ✓ checkmarks and re-bounces the servers, and only one invocation is needed because the siblings are already on disk and have populated `.env` files.

> **Why three invocations on cold boot?** `bin/ecosystem-build` runs Phase 4 (secrets / `.env`) *before* Phase 5 (cloning siblings). On the very first time through, Phase 4 only has `mcritchie_studio` to write `.env` for — the sibling repos don't exist yet. Phase 5 clones them, but Phase 6's `db:seed` then fails for the sibling without `RAILS_MASTER_KEY`. The third invocation closes the loop. This is a known wart; the workaround is two extra seconds of CPU.

**Where it puts things** (override with `PROJECTS_DIR=...`):
- All 5 repos live under `~/projects/`
- McRitchie Studio at http://localhost:3000
- Turf Monster at http://localhost:3001
- Login: `alex@mcritchie.studio` / `password`

See [`docs/agents/system/house-burn-down.md`](docs/agents/system/house-burn-down.md) for the full protocol, the 12 gotchas it encodes, and the per-phase fallback steps when something breaks.

---

## Single-app dev (when you already have the toolchain)

If your machine already has Ruby 3.1.7, Postgres 14, and an `.env` in place:

```bash
git clone https://github.com/amcritchie/mcritchie_studio.git
cd mcritchie_studio
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

Seeds load 4 agents with avatars, 9 skills, sample tasks, plus 32 NFL + 71 NCAA + 48 FIFA teams, ~2400 active contracts, ~570 PFF-graded athletes, and 47 news articles. Visit http://localhost:3000.

## Prerequisites (single-app path)

- Ruby **3.1.7** (use `brew install ruby@3.1` — not mise/rbenv; see [house-burn-down.md gotcha 1](docs/agents/system/house-burn-down.md))
- PostgreSQL 14+
- Node.js **20+** (Node 18 breaks `turf_vault`'s yarn deps)
- Bundler 2.4+ (`gem install bundler`)

## Test

```bash
# Rails tests
bin/rails test                  # 504 runs, 1322 assertions

# Playwright E2E (chromium only — skip @devnet which needs a funded wallet)
npm test                        # 42 tests
npm run test:headed             # with visible browser
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
