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

## Security Notes

- Never commit `.env` files or credential files
- API is currently open (no auth) — suitable for local/trusted networks only
- Google OAuth credentials must be configured per environment
- Password hashing uses bcrypt via `has_secure_password`
