# Credentials

## Environment Variables

All sensitive credentials are stored as environment variables, never in code.

### Required
- `DATABASE_URL` — PostgreSQL connection string (production only)

### Optional
- `GOOGLE_CLIENT_ID` — Google OAuth client ID
- `GOOGLE_CLIENT_SECRET` — Google OAuth client secret
- `RAILS_MASTER_KEY` — Rails encrypted credentials key

## Development Defaults

- Database: `mcritchie_studio_development` (local PostgreSQL, no password)
- Admin login: `alex@mcritchie.studio` / `pass`
- API: No authentication required (add token auth later)

## Agent Email Accounts

All agents share a primary Gmail account and have individual forwarding addresses on the `mcritchie.studio` domain.

### Shared Account
- **Email**: `bot@mcritchie.studio` — shared Gmail account used by all agents
- **1Password**: Credentials stored in the `bot@mcritchie.studio` 1Password vault (Gmail login, Solana wallets)

### Per-Agent Forwarding Addresses
Each agent has a dedicated email that forwards to the shared `bot@mcritchie.studio` inbox:

| Agent | Email | Purpose |
|-------|-------|---------|
| Alex | `admin@mcritchie.studio` | Orchestrator, admin notifications |
| Mack | `mack@mcritchie.studio` | Worker agent comms |
| Mason | `mason@mcritchie.studio` | Infrastructure alerts, deploy notifications |
| Turf Monster | `turf@mcritchie.studio` | Sports data, Turf Monster app notifications |

### Solana Wallets
Each agent has a dedicated Solana wallet. Keypairs are stored in the `bot@mcritchie.studio` 1Password vault.

## Security Notes

- Never commit `.env` files or credential files
- API is currently open (no auth) — suitable for local/trusted networks only
- Google OAuth credentials must be configured per environment
- Password hashing uses bcrypt via `has_secure_password`
- 1Password vault access is managed by Alex (human) — agents do not have direct vault access
