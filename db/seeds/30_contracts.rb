# Contracts are created inline by the people seed files (20_*, 21_*, 22_*)
# This file exists as a placeholder for any additional contract logic.
#
# Contract sources:
#   20_people_nfl_prospects.rb — 100 college contracts (expires_at: 2026-04-01)
#   21_people_nfl_stars.rb     — 32 NFL star contracts (with annual_value_cents)
#   22_people_fifa_stars.rb    — 48 FIFA national team contracts (no salary)
#
# Total: ~180 contracts

puts "Contracts: #{Contract.count} total (#{Contract.where.not(expires_at: nil).count} with expiration, #{Contract.where.not(annual_value_cents: nil).count} with salary)"
