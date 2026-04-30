# NFL Contracts — Spotrac salary overlay
#
# Source:  db/seeds/data/spotrac_contracts.json (~2,500 active NFL contracts)
# Service: Spotrac::SyncContracts (matches by otc_id when present, name otherwise)
#
# Identity is seeded by `bin/rails nfl:players_seed` (nflverse master CSV).
# This step layers salary on top: find or create the active Contract, set
# annual_value_cents, expires_at, sync Athlete.team_slug.
#
# Idempotent — re-runs are no-ops when JSON is unchanged. Run independently
# any time via `bin/rails nfl:salaries_sync`.

Spotrac::SyncContracts.new.call
