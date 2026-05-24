# Credentials

> **Restoring credentials on a fresh Mac?** `bin/ecosystem-build` does this automatically: it pulls `RAILS_MASTER_KEY` and other env vars from `heroku config` and `SOLANA_ADMIN_KEY` from 1Password (`agent.solana`), then writes `.env` for both Rails apps. See [house-burn-down.md](house-burn-down.md). This doc is the canonical reference for what each value is and where it lives.

## Environment Variables

All sensitive credentials are stored as environment variables, never in code.

### Required
- `DATABASE_URL` — PostgreSQL connection string (production only)

### Optional
- `GOOGLE_CLIENT_ID` — Google OAuth client ID
- `GOOGLE_CLIENT_SECRET` — Google OAuth client secret
- `RAILS_MASTER_KEY` — Rails encrypted credentials key
- `SOLANA_ADMIN_KEY` — Alex Bot's Solana private key (base58), used by Turf Monster for onchain operations
- `ANTHROPIC_API_KEY` — Claude API key for AI chat (McRitchie Studio)
- `X_BEARER_TOKEN` — X (Twitter) API bearer token for News intake (McRitchie Studio). See `docs/agents/system/news-pipeline.md` for setup.

## Development Defaults

- Database: `mcritchie-studio_development` (local PostgreSQL, no password)
- Admin login: `alex@mcritchie.studio` / `password`
- API: No authentication required (add token auth later)

## Agent Email Accounts

All agents share a primary Gmail account and have individual forwarding addresses on the `mcritchie.studio` domain.

### Shared Account
- **Email**: `bot@mcritchie.studio` — shared Gmail account used by all agents
- **1Password**: Credentials stored in the `alex@mcritchie.studio` 1Password account

### Per-Agent Forwarding Addresses
Each agent has a dedicated email that forwards to the shared `bot@mcritchie.studio` inbox:

| Agent | Email | Purpose |
|-------|-------|---------|
| Alex | `admin@mcritchie.studio` | Orchestrator, admin notifications |
| Avi | `avi@mcritchie.studio` | Product Owner — PR review, release sign-off, ticket grooming |
| Carl | `carl@mcritchie.studio` | Dev Backend Expert — Rails, ActiveRecord, jobs |
| Shannon | `shannon@mcritchie.studio` | Dev UI Expert — frontend, Tailwind, Alpine, theme |
| Jasper | `jasper@mcritchie.studio` | Dev Blockchain Expert — turf-vault, solana-studio, Phantom |
| Steffon | `steffon@mcritchie.studio` | Infrastructure Expert — Heroku, deploys, CI, OPSEC |
| Turf Monster | `turf@mcritchie.studio` | Sports data, Turf Monster app notifications |
| Mack | `mack@mcritchie.studio` | Worker agent comms — scraping, processing, bulk ops |
| Mason | `mason@mcritchie.studio` | Marketing — brand voice, launch comms, social, funnels (was Infrastructure pre 2026-05-23 — see `mission.md`) |

> The 5 new agents (Avi/Carl/Shannon/Jasper/Steffon) were added 2026-05-23 alongside Mason's pivot from Infrastructure to Marketing. Forwarding addresses still need to be created on the `mcritchie.studio` domain — operator action — but the persona definitions live at `docs/agents/agents/<slug>/`.

## Solana Wallets

Each agent has a dedicated Solana wallet on devnet. Credentials stored in 1Password.

### Wallet Addresses

| Agent | Address | Role |
|-------|---------|------|
| Alex Bot | `F6f8h5yynbnkgWvU5abQx3RJxJpe8EoQmeFBuNKdKzhZ` | Primary vault admin (signs all onchain ops) |
| Alex Human | `7ZDJp7FUHhuceAqcW9CHe81hCiaMTjgWAXfprBM59Tcr` | Backup vault admin (recovery only) |
| Mason | `CytJS23p1zCM2wvUUngiDePtbMB484ebD7bK4nDqWjrR` | Agent wallet |
| Mack | `foUuRyeibadQoGdKXZ9pBGDqmkb1jY1jYsu8dZ29nds` | Agent wallet |
| Turf Monster | `BLSBw8fXHzZc5pbaYCKMpMSsrtXBTbWXpUPVzMrXx9oo` | Agent wallet |

### 1Password CLI Access

Wallet credentials are stored in the `alex@mcritchie.studio` 1Password account. Use the CLI to retrieve them programmatically.

**Prerequisites**: Install `brew install 1password-cli`, then enable "Integrate with 1Password CLI" in 1Password desktop app (Settings > Developer).

**Account ID**: `MWOV5OT5BRHATI4EGMN26C5DPA`

**Vault layout**:
- `agents` — All agent wallet credentials (renamed from "🦞 Bots" 2026-05-03)
- `🧱 Blockchain` — General blockchain credentials

**Retrieve a wallet's private key** (items renamed 2026-05-03 to `agent.*` convention):
```bash
# Alex Bot
op item get "agent.solana" --vault "agents" --account MWOV5OT5BRHATI4EGMN26C5DPA --fields "private key"

# Mason
op item get "agent.mason.solana" --vault "agents" --account MWOV5OT5BRHATI4EGMN26C5DPA --fields "private key"

# Mack
op item get "agent.mack.solana" --vault "agents" --account MWOV5OT5BRHATI4EGMN26C5DPA --fields "private key"

# Turf Monster
op item get "agent.turf.solana" --vault "agents" --account MWOV5OT5BRHATI4EGMN26C5DPA --fields "private key"
```

**Set as env var (one-liner)**:
```bash
export SOLANA_ADMIN_KEY=$(op item get "agent.solana" --vault "agents" --account MWOV5OT5BRHATI4EGMN26C5DPA --fields "private key")
```

**Item fields**: Each wallet entry contains `recovery phrase`, `private key` (base58), and `wallet address` (base58 public key).

### Onchain Admin

Alex Bot is the primary admin for the TurfVault smart contract (program `Dx8uGU5w7B9NytDSsW4kseGZuqdVVRq1KY1mGXN2GaCT`). Alex Human is the backup admin. Both can perform admin actions (create/settle/close contests). The `SOLANA_ADMIN_KEY` env var in Turf Monster's `.env` holds Alex Bot's private key.

## Security Notes

- Never commit `.env` files or credential files
- API is currently open (no auth) — suitable for local/trusted networks only
- Google OAuth credentials must be configured per environment
- Password hashing uses bcrypt via `has_secure_password`
- 1Password CLI requires biometric or password auth on each use — credentials are never cached in plaintext
- Private keys should only be stored in 1Password and `.env` files (gitignored), never in code or commits
