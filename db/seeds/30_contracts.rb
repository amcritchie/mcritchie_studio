# Backfill contract_type for contracts created by 20_*, 21_*, 22_* seed files
#
# Contract sources:
#   20_people_nfl_prospects.rb — 100 college contracts (expires_at: 2026-04-01)
#   21_people_nfl_stars.rb     — 32 NFL star contracts (with annual_value_cents)
#   22_people_fifa_stars.rb    — 48 FIFA national team contracts (no salary)
#
# Total: ~180 contracts

# College contracts: have expires_at but no salary
Contract.where.not(expires_at: nil).where(annual_value_cents: nil).where(contract_type: "active").update_all(contract_type: "college")

# Active contracts: have annual_value_cents (NFL stars)
Contract.where.not(annual_value_cents: nil).where(contract_type: "college").update_all(contract_type: "active")

college_count = Contract.where(contract_type: "college").count
active_count  = Contract.where(contract_type: "active").count
draft_count   = Contract.where(contract_type: "draft_pick").count

puts "Contracts: #{Contract.count} total (#{college_count} college, #{active_count} active, #{draft_count} draft_pick)"
