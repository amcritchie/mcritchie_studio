# turf-vault Mainnet Rollout — 3-Phase Checklist

> **When to read this:** You're ready to ship `turf-vault` to mainnet. Don't skip phases. Each gate exists because the previous one's success isn't yet proven.

## Pre-flight (do all of these BEFORE Phase A)

- [ ] External audit completed (see [`turf-vault-audit-rfp.md`](./turf-vault-audit-rfp.md))
- [ ] All Critical + High findings fixed and re-audited
- [ ] Squads multisig upgrade authority transferred and rehearsed (see [`squads-upgrade-authority-migration.md`](./squads-upgrade-authority-migration.md))
- [ ] IDL hash pinning live in production turf-monster (ecosystem audit Tier 3 #22). `EXPECTED_IDL_HASH` set in Heroku.
- [ ] Devnet integration suite green for at least 7 consecutive nights (ecosystem audit Tier 3 #21 — nightly Playwright @devnet job)
- [ ] Sentry wired up + receiving events (ecosystem audit Tier 2 #15)
- [ ] Reconciler cron running + alert webhook validated (ecosystem audit Tier 2 #17)
- [ ] Secrets-rotation runbook reviewed; all secrets rotated within last 90 days (ecosystem audit Tier 2 #18)
- [ ] Bug bounty live on Immunefi (or scheduled to launch with Phase A)
- [ ] Communications plan: who announces, on what channels, what to say if things break

## Phase A — Mainnet smoke (1-2 weeks)

**Goal:** prove the deployed mainnet program works in production conditions with zero blast radius if anything is wrong.

**Constraints:**
- Internal users only (3 multisig signers, no public access)
- Single test contest with **$5-10 total at risk** (small entry fees, small prize pool)
- Mainnet account funding from a dedicated low-balance wallet — not from significant treasury

**Steps:**
1. Deploy `turf-vault` to mainnet (audit-signed-off version) with single key as initial upgrade authority.
2. Run the full Phase 4 Squads upgrade-authority migration (see runbook).
3. Initialize VaultState with the 3 mainnet multisig signers + threshold 2.
4. Create a USDC ATA for the vault.
5. Each of the 3 signers deposits a small amount (e.g. $5 each) via the Rails app pointed at mainnet.
6. Create an internal contest with entry fee $1, max 3 entries.
7. Each signer enters one matchup set.
8. Simulate games or wait for real game results.
9. Settle contest (admin signs as `admin`, cosigner signs via Squads/Phantom).
10. Verify each signer receives correct payout in their wallet.
11. Reconciler runs + reports no discrepancies.
12. Withdraw all remaining balances. Verify zero balance in vault PDA.

**Phase A gates → go to Phase B when ALL of these are true:**
- [ ] 5+ successful end-to-end test contests (create → enter → settle → withdraw)
- [ ] Zero Reconciler discrepancies for 7 consecutive days
- [ ] No Sentry-paged exceptions related to Solana code in 7 days
- [ ] Multisig cosign flow worked smoothly each time (no manual recovery needed)
- [ ] At least one no-op upgrade proposal rehearsed through Squads on mainnet

## Phase B — Real users, capped (4 weeks)

**Goal:** prove the system handles real money + real users under realistic load, but with the blast radius capped so a worst-case bug is recoverable.

**Constraints:**
- Public-facing, but with hard caps
- **Per-contest TVL cap: $500-1000** (sum of entry fees + prizes)
- **Daily mint cap: $5000 total deposits across all users**
- Daily withdraw cap: $5000 (forces partial recovery in case of bug)
- Show "Beta" badge on the UI

**Implementation needs:**
- Add daily-totals tracking to Rails — `Daily::Totals.deposits_today`, `Daily::Totals.contest_tvl(id)`
- Block deposit endpoint if daily total exceeds cap
- Block contest creation if proposed TVL exceeds per-contest cap
- Surface caps in UI ("$X of $5000 daily limit remaining")
- Add admin override for emergencies (signed by 2-of-3 multisig)

**Communications:**
- Public launch post (X, blog, anywhere @turfmonstershow has reach)
- "Beta" badge prominently displayed on the UI + every contest
- Discord/Slack support channel for users who hit caps or have questions

**Phase B gates → go to Phase C when ALL of these are true:**
- [ ] 50+ contest settlements completed
- [ ] Zero Reconciler divergence > $1 across the whole period
- [ ] Zero unrecovered Sentry pages
- [ ] No multisig cosign failures
- [ ] No need to use Squads override or `force_close_vault`
- [ ] User feedback channel has no unresolved bug reports
- [ ] (Optional) follow-up audit pass on any code added during Phase B

## Phase C — Uncapped (ongoing)

**Goal:** normal operation. Caps lifted; growth driven by demand.

**Steps:**
1. Lift per-contest TVL cap and daily totals.
2. Remove "Beta" badge.
3. Continue Reconciler cron, Sentry monitoring, weekly multisig health checks.
4. Re-run external audit annually OR when significant new code lands (`update_signers` of new signers, new instruction added, etc.).

**Ongoing operational rituals:**
- **Weekly**: review Reconciler discrepancy reports (if any), confirm Sentry error rate is flat/down
- **Monthly**: rehearse a no-op upgrade through Squads (so the muscle memory + signer availability stays current)
- **Quarterly**: secrets rotation per [secrets-rotation runbook](./secrets-rotation.md)
- **Annually**: re-audit (especially if new instructions added)

## If something breaks in Phase A or B

**Symptom → first action**:

| Symptom | First action |
|---------|--------------|
| Reconciler discrepancy alert | Read ErrorLog + run `bin/rails solana:reconcile_user ADDRESS=<wallet>` to see specifics. Don't drain vault. |
| User reports lost funds | Check on-chain via `solana account <user_pda>` — if balance is correct on-chain, it's a Rails/UI bug, not lost funds. |
| Sentry: signature verification failure cluster | Check IDL hash. May indicate program drift. |
| Squads cosign not landing | Check signer availability. Use Squads UI to inspect the proposal state. |
| Mass settlement failure | DON'T retry blindly. Check what was actually written on-chain via `anchor view`. Reconciler shows truth. |
| Suspected compromise of any signer key | Immediate `update_signers` via 2-of-3 cosign by the other two. Replace compromised signer. |

**If you need to halt operations** (worst case):
- Pause Rails-side contest entry endpoint (set a `Contests::EntryOpen = false` flag, surface in UI).
- This doesn't pause on-chain — already-entered contests still settle normally.
- Don't `force_close_vault` unless you can prove user funds are at risk; that's a one-way operation.

## Communication template (worst case)

If a critical bug surfaces and you need to communicate publicly:

```
Hi everyone — we discovered <brief description of issue> in turf-monster
at <time>.

What happened: <facts only; no speculation>
What we're doing: <specific actions>
Funds status: <"all funds are safe and accounted for" OR "X users affected, we're contacting directly">
Timeline: <expected resolution window>

We'll post updates every <N> hours until resolved.

— Alex
```

Be specific about funds status — vague language amplifies panic.

## Post-launch: what gets easier vs harder

**Easier**:
- New contest creation (everything's hot, no cold-start)
- Settlement (well-rehearsed cosign flow)
- Adding satellites (engine + scaffolder are in place per audit Tier 2 #11 + Tier 3 #24)

**Harder**:
- Schema migrations (multisig adds friction)
- Signer rotation if someone leaves the team (requires 2-of-3 from existing signers, then a Squads members rotation, then `update_signers` on-chain)
- Reputational recovery from any user-facing bug (slow, painful — invest disproportionately in monitoring)

## Decision log

When you decide to advance from one phase to the next, record:
- Date of decision
- Who decided
- Which gates were specifically met
- Any waived gates and why

Keep this in a simple table at the end of this file or a separate runlog. The record matters if a Phase C bug surfaces and you need to trace what was tested vs assumed.
