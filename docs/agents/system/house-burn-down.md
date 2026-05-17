# House Burn-Down Recovery Protocol

How to rebuild the entire McRitchie dev environment from a freshly-reset Mac. Covers all 5 repos in the ecosystem.

**Time budget**: ~60-90 min on a decent connection. Most of it is unattended (Ruby compile, Solana toolchain install). Active work is ~15 min.

## The Ecosystem

| Repo | Role | Stack | Port |
|------|------|-------|------|
| [`mcritchie_studio`](https://github.com/amcritchie/mcritchie_studio) | Flagship hub. Task/News/Content pipelines, NFL data, SSO hub | Rails 7.2 / Postgres | 3000 |
| [`turf_monster`](https://github.com/amcritchie/turf_monster) | Sports pick'em (World Cup 2026). SSO satellite of the hub. Solana onchain | Rails 7.2 / Postgres / Redis | 3001 |
| [`studio`](https://github.com/amcritchie/studio) | Shared Rails engine: auth, SSO, error logging, theme, ImageCache | Ruby gem | — |
| [`solana_studio`](https://github.com/amcritchie/solana_studio) | Ruby Solana client (RPC, ed25519, borsh, txns) | Ruby gem | — |
| [`turf_vault`](https://github.com/amcritchie/turf_vault) | Onchain escrow vault. 2-of-3 multisig. Consumed by Turf Monster | Anchor / Rust / Solana | — |

**Dependency graph (build order):**

```
studio gem ──┐
             ├──> mcritchie_studio (flagship)
             └──> turf_monster ──> solana_studio gem
                                ──> turf_vault (devnet, already deployed)
```

Both Rails apps `bundle install` the studio + solana_studio gems direct from GitHub — no local clone of the engine repos is required for bringup, only for editing them.

---

## Fast path (the only commands you should need)

On a fresh Mac with Homebrew already installed:

```bash
# 1. Clone the flagship — every other repo + script lives downstream of this one
git clone https://github.com/amcritchie/mcritchie_studio.git ~/projects/mcritchie_studio
cd ~/projects/mcritchie_studio

# 2. First pass — installs all brew packages (incl. 1Password CLI), Rust, Solana,
#    Anchor, etc. Bails at Phase 4 once it needs your 1Password service token.
bin/ecosystem-build

# 3. Copy your 1Password service account token (ops_...) to clipboard, then:
bin/setup-1pass-token

# 4. Second pass — picks up at Phase 4 with the token now set, restores .env
#    from Heroku + 1Password, clones the other 4 repos, bundles + DBs + Anchor,
#    bounces both Rails servers.
bin/ecosystem-build
```

That's it. ~25-30 min wall time on a fresh machine; the only thing you actually do is copy the token and run three commands. On every later machine the second pass takes ~30 s — it just walks ✓ checkmarks and re-bounces the servers.

**Re-running anytime:** `bin/ecosystem-build` is fully idempotent. Run it after pulling new commits, switching branches, or anytime you want to confirm "everything still works." It will reset both Rails servers to a clean dev state.

**Custom project layout:** set `PROJECTS_DIR` to override `~/projects` (e.g. `PROJECTS_DIR=~/code bin/ecosystem-build`). The script clones siblings into that directory.

**Full NFL data (opt-in):** the default build seeds players from a Spotrac snapshot but skips ESPN headshots + the real schedule (so `/nfl-rosters` shows empty position-labeled circles). To populate the full NFL pipeline, run `WITH_NFL_DATA=1 bin/ecosystem-build` — adds ~10-15 min for nflverse schedule pull + ESPN headshot caching to S3. Requires AWS creds in `.env` (auto-restored by Phase 4).

The manual phase-by-phase steps below are kept as a fallback for debugging when the script can't complete a phase.

---

## Phase 0 — Prereqs

You need these *already installed* before this protocol can start:

- macOS with Xcode Command Line Tools (`xcode-select --install` if missing)
- Homebrew (`brew --version`)
- `git` (ships with Xcode CLT)
- The 5 GitHub repos accessible to your account (HTTPS clone works)
- A 1Password service account token with read access to the `agents` vault (account `alex@mcritchie.studio` / `MWOV5OT5BRHATI4EGMN26C5DPA`)

`bin/ecosystem-build` handles everything else.

---

## Phase 1 — System tools (one brew command)

```bash
brew update && brew install \
  ruby@3.1 \
  mise \
  postgresql@14 \
  redis \
  1password-cli \
  gh \
  imagemagick \
  ffmpeg \
  libpq \
  heroku/brew/heroku
```

~5 min. Installs:
- **ruby@3.1** — Ruby 3.1.7 with the full stdlib (mise/ruby-build skips `socket` on Darwin 25 — see Gotcha 1)
- **mise** — version manager for Node (not Ruby — see above)
- **postgresql@14** — local DB for both Rails apps
- **redis** — Sidekiq queue for Turf Monster
- **1password-cli** (`op`) — secret retrieval
- **gh** — GitHub CLI
- **imagemagick** — image resizing for studio engine's `ImageCache`
- **ffmpeg** — lineup-graphic video assembly (Starter Post X/TikTok workflows)
- **libpq** — `pg` gem build deps
- **heroku** — deploys

Start the background services:

```bash
brew services start postgresql@14
brew services start redis
```

The brew Postgres install creates a superuser matching your macOS login name with no password. Rails apps' `database.yml` uses default role + no password, so they connect fine without further setup.

---

## Phase 2 — Shell setup

Append to `~/.zshrc` (idempotent — check before adding):

```bash
# Ruby via Homebrew (keg-only — must be added to PATH explicitly)
export PATH="/opt/homebrew/opt/ruby@3.1/bin:$PATH"
export PATH="/opt/homebrew/lib/ruby/gems/3.1.0/bin:$PATH"

# mise — Node (and other non-Ruby langs) version manager
eval "$(/opt/homebrew/bin/mise activate zsh)"

# Solana CLI
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Cargo (Rust)
export PATH="$HOME/.cargo/bin:$PATH"
```

Then either `source ~/.zshrc` or open a new terminal. Verify: `which ruby` → `/opt/homebrew/opt/ruby@3.1/bin/ruby`.

---

## Phase 3 — Languages

### Node + yarn (via mise)

```bash
mise use --global node@20
npm install -g yarn
```

~30s. Node 20 (not 18) is required — `turf_vault`'s TypeScript test deps (`@solana/codecs-numbers`) need Node ≥ 20.18.0. Both Rails apps' Playwright deps are fine on either, but pinning to 20 keeps everything consistent.

### Ruby — already installed in Phase 1

Brew's `ruby@3.1` formula gives you Ruby 3.1.7 with the complete stdlib. Verify:

```bash
ruby --version                                          # ruby 3.1.7 (...)
ruby -e "require 'socket'; puts Socket.gethostname"     # should print your hostname
```

If `socket` errors here, you're picking up the wrong Ruby — re-check Phase 2 PATH order.

### Rust + Solana CLI + Anchor

```bash
# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"
rustup install 1.89.0
rustup default 1.89.0

# Solana CLI (Anza — release.solana.com is deprecated)
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Anchor (uses Rust + cargo)
cargo install anchor-cli --version 0.32.1 --locked
```

~10-15 min. Anchor compile is the longest single step.

**Gotcha**: The Solana installer appends PATH to `~/.profile` (bash convention), which zsh doesn't read by default. The PATH line in Phase 2's `~/.zshrc` block handles this — don't skip it.

Verify:
```bash
rustc --version    # rustc 1.89.0
solana --version   # solana-cli 3.x (Agave)
anchor --version   # anchor-cli 0.32.1
```

### Solana keypair (for local Anchor testing)

```bash
solana-keygen new --no-bip39-passphrase --silent --outfile ~/.config/solana/id.json
solana config set --url devnet
solana address  # confirm your new pubkey
```

This is a **local dev keypair**, NOT one of the agent vault wallets. The agent wallets (Alex Bot, Mason, Mack, Turf Monster) stay in 1Password.

---

## Phase 4 — Clone all repos

```bash
mkdir -p ~/projects && cd ~/projects
gh repo clone amcritchie/mcritchie_studio
gh repo clone amcritchie/turf_monster
gh repo clone amcritchie/studio
gh repo clone amcritchie/solana_studio
gh repo clone amcritchie/turf_vault
```

(`gh auth login` first if not authenticated.)

---

## Phase 5 — Secrets

Two layers:

### 5a. 1Password CLI auth (via service account token)

Use a **service account token** rather than the desktop app integration — it avoids Touch ID prompts per call and works headlessly. One-time setup:

1. Sign into https://start.1password.com as `alex@mcritchie.studio` (account `MWOV5OT5BRHATI4EGMN26C5DPA`)
2. **Developer Tools → Service Accounts → Create Service Account**
3. Grant **read** access to the `agents` vault (and `🧱 Blockchain` if you'll need it)
4. Copy the token (`ops_...` — only shown once)
5. Copy that token to your clipboard (Cmd+C)
6. From the `mcritchie_studio` repo, run:

```bash
bin/setup-1pass-token
```

The script reads from `pbpaste`, validates the prefix, strips whitespace, writes `OP_SERVICE_ACCOUNT_TOKEN` to `~/.zprofile` (idempotent + `chmod 600`), and verifies with `op vault list`. Token never touches shell parsing — bypasses all the smart-quote / line-wrap / newline-in-paste failure modes that broke direct `! echo ops_… >> ~/.zprofile` attempts. See Gotcha 12.

After it succeeds, `source ~/.zprofile` (or open a new terminal) to load the export.

**To rotate the token later**, just re-copy and re-run `bin/setup-1pass-token` — it replaces the existing line.

### 5b. Per-app .env files

The Rails apps read `.env` via Rails' default dotenv (or the `dotenv-rails` gem). Restore each:

**`/Users/alex/projects/mcritchie_studio/.env`** — see `docs/agents/system/credentials.md` for the canonical list. Minimum to boot:

```bash
RAILS_MASTER_KEY=$(heroku config:get RAILS_MASTER_KEY --app mcritchie-studio)
GOOGLE_CLIENT_ID=...                  # Google Cloud Console
GOOGLE_CLIENT_SECRET=...
ANTHROPIC_API_KEY=...                 # 1Password: "anthropic" in agents vault
X_BEARER_TOKEN=...                    # 1Password: "x.api" (read)
X_API_KEY=...                         # 1Password: "x.api" (write — Read+Write app)
X_API_SECRET=...
X_ACCESS_TOKEN=...
X_ACCESS_TOKEN_SECRET=...
HIGGSFIELD_API_KEY=...                # 1Password: "agent.higgesfield"
HIGGSFIELD_API_SECRET=...
TIKTOK_CLIENT_KEY=...                 # 1Password: "🐊 TikTok"
TIKTOK_CLIENT_SECRET=...
TIKTOK_REFRESH_TOKEN=...
TIKTOK_OPEN_ID=...
AWS_ACCESS_KEY_ID=...                 # S3 ImageCache bucket
AWS_SECRET_ACCESS_KEY=...
```

**`/Users/alex/projects/turf_monster/.env`** — see `turf_monster/docs/SOLANA.md` for full list. **`RAILS_MASTER_KEY` is not optional** — `db:seed` calls `User#generate_managed_wallet!` which reads `Rails.application.credentials.secret_key_base` to encrypt the wallet. Without the key, seed crashes mid-run with `undefined method '[]' for nil:NilClass`.

```bash
RAILS_MASTER_KEY=$(heroku config:get RAILS_MASTER_KEY --app turf-monster)
GOOGLE_CLIENT_ID=...                  # may differ from mcritchie_studio
GOOGLE_CLIENT_SECRET=...
SOLANA_ADMIN_KEY=$(op item get "agent.solana" --vault agents --fields "private key")
SOLANA_RPC_URL=https://api.devnet.solana.com   # or paid provider if rate-limited
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

**Shared `/Users/alex/projects/.env`** (referenced by Turf Monster's CLAUDE.md for AWS) — keep this minimal, only put truly cross-app vars here.

### 5c. Heroku CLI login

```bash
heroku login   # opens browser
heroku apps    # should list mcritchie-studio and turf-monster
```

This is what unlocks the `heroku config:get` commands above.

---

## Phase 6 — Per-app bringup

### 6a. mcritchie_studio (flagship — bring this up first)

```bash
cd ~/projects/mcritchie_studio
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server                   # port 3000
```

Visit http://localhost:3000. Login `alex@mcritchie.studio` / `password`.

Seeds load 4 agents, 9 skills, sample tasks, 32 NFL + 71 NCAA + 48 FIFA teams, ~2400 active contracts, ~570 PFF-graded athletes. The `db:seed` phase 32 (`32_headshot_links.rb`) makes network calls — safe to let it run, or skip with `SKIP_NETWORK_SEEDS=1` if behind a firewall.

For full NFL data (UDFAs, depth charts, ESPN headshots cached to S3), run the `/nfl-rebuild` claude skill, which chains `db:reset` → `db:seed` → `nfl:players_seed` → `espn:scrape_depth_charts`. Requires AWS creds in `.env`.

For the lineup capture (Starter Post X workflow) and Playwright e2e tests:
```bash
npm install              # installs Playwright + Chromium
npm test                 # 13 e2e smoke tests
```

### 6b. turf_monster

```bash
cd ~/projects/turf_monster
bundle install
bin/rails db:create db:migrate db:seed
bin/dev                  # starts web (3001) + Tailwind watcher + Sidekiq worker
```

Visit http://localhost:3001. Login same admin.

`bin/dev` (vs `bin/rails server`) is the right command — it launches the Procfile.dev which includes Sidekiq. If Sidekiq dies, check Redis: `brew services list | grep redis`.

### 6c. solana_studio (gem, no bringup)

```bash
cd ~/projects/solana_studio
bundle install
ruby -Itest test/keypair_test.rb test/borsh_test.rb test/transaction_test.rb
```

Library only — no server. Only clone locally if editing.

### 6d. studio (gem, no bringup)

```bash
cd ~/projects/studio
bundle install
```

Engine only — no DB, no server, no tests of its own. Test it via the consuming apps' suites. Only clone locally if editing the engine.

After editing the engine and pushing to GitHub:
```bash
cd ~/projects/mcritchie_studio && bundle update studio
cd ~/projects/turf_monster && bundle update studio
```

### 6e. turf_vault (Anchor smart contract)

```bash
cd ~/projects/turf_vault
yarn install                                 # TypeScript test deps (ts-mocha, @solana/codecs-*)
anchor build                                 # ~3-5 min on first build
anchor test                                  # spins up local validator, runs 25 ts tests
```

Already deployed to devnet (program ID `7Hy8GmJWPMdt6bx3VG4BLFnpNX9TBwkPt87W6bkHgr2J`) — local builds are for development only.

**Gotcha**: `anchor test` will fail with `ts-mocha: command not found` if you skip `yarn install`. The Anchor scaffold's test runner is JS, not Rust.

To deploy a new version (requires multisig cosign for existing vault):
```bash
solana config set --url devnet
anchor deploy --provider.cluster devnet
```

---

## Phase 7 — Smoke test the ecosystem

1. **Hub running**: http://localhost:3000 → dashboard renders, can log in
2. **Satellite running**: http://localhost:3001 → contests list renders
3. **SSO**: Click "Turf Monster" link in mcritchie_studio admin gear → should land logged-in on turf_monster (requires shared `SECRET_KEY_BASE`, i.e. same `RAILS_MASTER_KEY`)
4. **Solana keypair**: `solana address` returns your pubkey
5. **Anchor local test**: `cd ~/projects/turf_vault && anchor test` — all 25 tests pass

---

## Appendix A — Gotchas encountered during this protocol

These are the surprises from the last burn-down. Pre-baked into the steps above; documented here so future-you knows *why*:

1. **Don't use mise/ruby-build for Ruby on Darwin 25 / Apple Silicon** — mise auto-applies `--with-ext=openssl,psych,+` which silently skips the `socket` C extension. Every `bundle exec` then dies with `cannot load such file -- socket (LoadError)`. Reproduces on Ruby 3.1.0 AND 3.1.7. Fix: use `brew install ruby@3.1` (always builds the full stdlib) and keep mise scoped to Node only. The `.ruby-version` files in both Rails apps say `3.1.0`, but brew Ruby reports `3.1.7`; bundler doesn't enforce patch level, so this is harmless.

2. **`release.solana.com` is deprecated** — returns SSL errors. Use `release.anza.xyz/stable/install`.

3. **Solana installer writes PATH to `~/.profile`** — zsh doesn't source `.profile` by default. The Phase 2 `~/.zshrc` block handles this explicitly.

4. **Bundler version drift** — Gemfile.lock pins `BUNDLED WITH 2.4.19`. mise's Ruby 3.1.7 ships with bundler 2.3.x and will auto-upgrade on first `bundle install`. Works fine if `socket` ext is present (Gotcha 1).

5. **System Ruby 2.6 is unusable** — macOS ships with ancient Ruby. Don't run `bundle` against it. mise's shims (`~/.local/share/mise/shims`) must be earlier on PATH than `/usr/bin`.

6. **Heroku LFS gotcha** — `mcritchie_studio` repo has LFS pointers in history (retired 2026-04-30) but Heroku's git remote doesn't speak LFS. Push with `git push heroku main --no-verify` to skip the LFS pre-push hook.

7. **Public devnet RPC is rate-limited** — `SOLANA_RPC_URL` defaults to public devnet which 429s under load. Use a paid provider (QuickNode, Helius) for serious work.

8. **Sidekiq dies silently without Redis** — Turf Monster's `bin/dev` includes the worker, but it'll just spin if Redis isn't running. Always: `brew services list | grep redis` first.

9. **TikTok app is in review** (submitted 2026-05-04) — only sandbox + manual posting paths work until Content Posting API approval. Don't expect API-direct posts to publish.

10. **`RAILS_MASTER_KEY` is a hard prerequisite for `turf_monster db:seed`** — not just for booting. `db/seeds/users.rb` calls `User#generate_managed_wallet!`, which encrypts the wallet's private key via `Rails.application.credentials.secret_key_base[0, 32]`. Without the master key, that returns nil and the seed dies. Restore the key **before** running `db:create db:migrate db:seed`.

11. **Don't tail-pipe `bin/rails db:seed`** — `bin/rails db:seed | tail -30` returns `tail`'s exit code (0), masking seed failures. Use `set -o pipefail` or run the seed without piping when verifying it ran clean.

12. **macOS Terminal mangles long secret pastes** — Multiple compounding failure modes when pasting tokens via shell commands:
    - **Smart quotes** (System Settings → Keyboard → Text Input → "Use smart quotes and dashes") silently convert `"` → `"` `"` on paste. zsh doesn't treat these as quote delimiters, so quoted strings get tokenized as bare words. Symptom: `zsh: command not found: WRITE OK` from `echo "WRITE OK"`.
    - **Line wrapping** in long commands can insert literal newlines mid-paste, splitting `chmod 600` into `chmod 60` + `\n` + `0 filename`.
    - **Token whitespace** — copy buffers sometimes wrap with `&nbsp;` or literal spaces inside base64url tokens.
    Solution: use `bin/setup-1pass-token` (which reads `pbpaste` → never goes through shell parsing). For one-off Heroku/etc. keys, use the same pattern: `KEY=$(pbpaste | tr -d '[:space:]')` rather than `KEY=ops_paste_here`.

---

## Appendix B — What `bin/ecosystem-build` does

Eight phases, executed in order. Each phase: detect current state → install/configure only what's missing → verify. Re-running is safe; on a healthy machine, every phase logs ✓ checkmarks.

| Phase | Responsibility |
|-------|----------------|
| 1. System tools | Homebrew packages (ruby@3.1, postgres@14, redis, mise, gh, heroku, etc.), starts Postgres + Redis services, verifies ruby socket extension |
| 2. Languages | Node 20 + yarn (via mise), Rust 1.89.0 (via rustup), Solana CLI (via Anza), Anchor 0.32.1 (via cargo), local Solana devnet keypair |
| 3. Shell config | `~/.zshrc` PATH lines (brew Ruby, mise activation, Solana, Cargo), `~/.zprofile` chmod 600 |
| 4. Secrets | Verifies `OP_SERVICE_ACCOUNT_TOKEN` works; pulls `agent.heroku` from 1Password into `HEROKU_API_KEY`; restores `.env` for both Rails apps from `heroku config` |
| 5. Sibling repos | `gh repo clone` for `turf_monster`, `studio`, `solana_studio`, `turf_vault` (skips ones already present) |
| 6. Bundles + DBs | `bundle install` + `db:create db:migrate db:seed` for each Rails app; bundle for `solana_studio` |
| 6b. NFL data (opt-in) | Only runs when `WITH_NFL_DATA=1`. Chains `nfl:schedule_seed YEAR=2026` (real schedule from nflverse) + `nfl:players_seed` (espn_ids + S3 headshot cache) + `espn:scrape_depth_charts` (live depth charts from ESPN) + `nfl:rosters_snapshot SEASON=2026-nfl` (snapshot fresh depth charts → current-week Rosters so `/games/2026/week/N/...` show pages render) + `nfl:upload_headshots`. ~10-15 min, needs AWS creds in `.env`. Without this, `/nfl-rosters` shows position-labeled placeholder circles and 2026 game show pages have no lineup data. |
| 7. Anchor + e2e | `yarn install` + `anchor build` for `turf_vault`; `npm install` for both Rails apps; `npx playwright install chromium` (~90 MB cached for e2e tests) |
| 8. Servers | Always kills + restarts: bounces both Rails apps on :3000 and :3001, curls each to verify HTTP 2xx/3xx |

If any phase fails, the script prints what to do and exits. Re-running picks up where it left off.

The one secret-input boundary is **Phase 4**: if the OP token isn't set, the script bails with instructions to run `bin/setup-1pass-token` first. That's the only step that can't be automated — by design (the token has to come from your clipboard).

---

## Appendix C — Tooling versions reference

What this protocol installed last successful run:

| Tool | Version | Source |
|------|---------|--------|
| Homebrew | latest | pre-existing |
| mise | latest | brew |
| Ruby | 3.1.7 | brew `ruby@3.1` |
| Node | 20.20.x | mise |
| yarn | 1.22.x | npm -g |
| Postgres | 14.x | brew (`postgresql@14`) |
| Redis | latest | brew |
| Rust | 1.89.0 | rustup (pinned) |
| Solana CLI | 3.1.x (Agave) | release.anza.xyz |
| Anchor | 0.32.1 | cargo |
| Bundler | 2.4.19 | auto-upgraded by Gemfile.lock |
| Heroku CLI | latest | brew |
| 1Password CLI | latest | brew |

---

## Appendix D — Cross-references

- `docs/agents/system/bootstrap.md` — first-time setup (one app, simpler)
- `docs/agents/system/credentials.md` — full env var + 1Password reference
- `docs/agents/system/news-pipeline.md` — News pipeline + X API setup
- `RUNBOOK.md` (top-level) — production troubleshooting (Heroku deploys, theme cache, SSO, OAuth)
- `turf_monster/docs/SOLANA.md` — Solana integration deep dive
- `turf_vault/README.md` — Anchor program structure + multisig
