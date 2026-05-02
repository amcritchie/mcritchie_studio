# NFL Contracts — Spotrac salary overlay (2025 NFL season)
#
# **Season-specific snapshot** — the JSON file is a point-in-time export of
# Spotrac contracts for the 2025 NFL season. When prepping a new season,
# create a sibling seed `22_nfl_contracts_<year>.rb` + JSON, retire this one,
# and update Spotrac::SyncContracts::DEFAULT_JSON_PATH.
#
# Source:  db/seeds/data/spotrac_contracts_2025.json (~2,500 active NFL contracts)
# Service: Spotrac::SyncContracts (matches by otc_id when present, name otherwise)
#
# Identity is seeded by `bin/rails nfl:players_seed` (nflverse master CSV).
# This step layers salary on top: find or create the active Contract, set
# annual_value_cents, expires_at, sync Athlete.team_slug.
#
# Idempotent — re-runs are no-ops when JSON is unchanged. Run independently
# any time via `bin/rails nfl:salaries_sync`.

Spotrac::SyncContracts.new.call
