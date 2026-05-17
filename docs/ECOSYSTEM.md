# McRitchie Ecosystem

Single orientation surface for the 5-repo McRitchie stack. Fresh contributors, fresh Claude sessions, and future-you start here.

## The Repos

| Repo | Role | Stack | Port |
|------|------|-------|------|
| [`mcritchie_studio`](https://github.com/amcritchie/mcritchie_studio) | Flagship hub. Task/News/Content pipelines, NFL data, SSO hub. Owns the ecosystem recovery scripts. | Rails 7.2 / Postgres | 3000 |
| [`turf_monster`](https://github.com/amcritchie/turf_monster) | Sports pick'em (World Cup 2026). SSO satellite. Solana onchain via turf_vault. | Rails 7.2 / Postgres / Redis | 3001 |
| [`studio`](https://github.com/amcritchie/studio) | Shared Rails engine: auth, SSO, error logging, theme, ImageCache. | Ruby gem | — |
| [`solana_studio`](https://github.com/amcritchie/solana_studio) | Ruby Solana client: RPC, ed25519, borsh, tx builder. | Ruby gem | — |
| [`turf_vault`](https://github.com/amcritchie/turf_vault) | Onchain escrow vault. 2-of-3 multisig. Consumed by turf_monster. | Anchor / Rust / Solana | — |

## Dependency graph

```
studio gem ──┐
             ├──> mcritchie_studio (flagship)
             └──> turf_monster ──> solana_studio gem
                                ──> turf_vault (devnet, already deployed)
```

Both Rails apps `bundle install` the `studio` + `solana_studio` gems direct from GitHub — no local clone of the engine repos is required for bringup, only for editing them.

## Where to start

| If you're… | Read first |
|------------|-----------|
| Setting up a fresh Mac | [`bin/ecosystem-build`](../bin/ecosystem-build) + [`docs/agents/system/house-burn-down.md`](agents/system/house-burn-down.md) |
| Onboarding to the codebase | [`CLAUDE.md`](../CLAUDE.md) (flagship) and the per-repo CLAUDE.md in any app you'll touch |
| Hardening for production | [`docs/agents/system/ecosystem-audit-2026-05-17.md`](agents/system/ecosystem-audit-2026-05-17.md) — current audit + tiered roadmap |
| Working on Solana | `turf_monster/docs/SOLANA.md` and `turf_vault/README.md` |
| Working on auth/SSO | `studio/CLAUDE.md` (auth section) and `turf_monster/docs/AUTH.md` |

## Per-repo summary

- **mcritchie_studio** — The hub. Hosts the SSO entry point that satellites consume. Runs the NFL data ingest pipeline (Nflverse → Spotrac → ESPN → PFF → depth chart), News pipeline (intake → review → process → refine → conclude), and Content pipeline (idea → hook → script → assets → assembly → posted). Owns `bin/ecosystem-build` and the recovery protocol. Read: `CLAUDE.md` for orientation, `docs/agents/system/house-burn-down.md` for recovery.
- **turf_monster** — Satellite. Sports pick'em UI + contest grading + Solana onchain settlement against `turf_vault`. Read: `CLAUDE.md` + the topic files in `docs/` (`AUTH.md`, `SOLANA.md`, `FORMULAS.md`, `UI_PATTERNS.md`, `world_cup_2026.md`).
- **studio** — Engine. Provides `Studio::ErrorHandling` concern, ErrorLog model, SSO contract, theme system (7 role colors → CSS vars), ImageCache, badge component (with shared stage-* palette). Consumed by mcritchie_studio + turf_monster + future apps. Read: `CLAUDE.md`.
- **solana_studio** — Gem. Primitives only: `Solana::Client` (JSON-RPC), `Solana::Borsh`, `Solana::Transaction` (Anchor discriminators + PDA derivation), `Solana::SplToken`, `Solana::Keypair`. Pure Ruby, ed25519 the only external dep. Consumed by turf_monster (which extends `Solana::Keypair` locally for encryption). Read: `CLAUDE.md` + `README.md`.
- **turf_vault** — Anchor program. 12 instructions (deposit/withdraw, create/enter/settle/close contest, multisig signer rotation), 4 account structs, 2-of-3 multisig on all sensitive ops. Deployed to devnet at `7Hy8GmJWPMdt6bx3VG4BLFnpNX9TBwkPt87W6bkHgr2J`. Read: `README.md` + `RUNBOOK.md`.

## Secret + service surface

- **1Password account**: `alex@mcritchie.studio` (`MWOV5OT5BRHATI4EGMN26C5DPA`), vault `agents`. Service-account token bootstraps everything else via `bin/setup-1pass-token`.
- **Heroku apps**: `mcritchie-studio` → https://app.mcritchie.studio; `turf-monster` → https://turf.mcritchie.studio. `RAILS_MASTER_KEY` shared across apps via Heroku config.
- **Solana**: devnet via Anza CLI (`release.anza.xyz/stable/install`). Local dev keypair at `~/.config/solana/id.json` — NOT one of the agent vault wallets. Agent wallets (Alex Bot / Mason / Mack / Turf Monster) stay in 1Password.
- **AWS S3**: per-app buckets (`mcritchie-studio-{dev,production}`, `turf-monster-{dev,production}`) for ImageCache.

## Recovery in 4 commands

On a fresh Mac with Homebrew installed:

```bash
git clone https://github.com/amcritchie/mcritchie_studio.git ~/projects/mcritchie_studio
cd ~/projects/mcritchie_studio
bin/ecosystem-build       # Phase 1-3: installs toolchain, bails at Phase 4 needing 1P token
bin/setup-1pass-token     # paste 1P token to clipboard first
bin/ecosystem-build       # Phase 4+: pulls .env from Heroku, clones siblings, bounces servers
```

Full protocol: [`docs/agents/system/house-burn-down.md`](agents/system/house-burn-down.md).

## Current audit + roadmap

The 2026-05-17 ecosystem audit at [`docs/agents/system/ecosystem-audit-2026-05-17.md`](agents/system/ecosystem-audit-2026-05-17.md) is the live reference for what's queued. Tiered: Tier 1 (half-day quick wins), Tier 2 (1-3 day cleanups), Tier 3 (week+ architectural / production-readiness). Re-run quarterly or when a new app joins.

---

*Last updated: 2026-05-17. Update on every Tier merge.*
