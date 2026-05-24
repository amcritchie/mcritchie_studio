# Mission

McRitchie Studio is the central task management and orchestration hub for the McRitchie AI agent system. It provides:

1. **Task Pipeline** — Create, assign, track, and transition tasks through stages (new → queued → in_progress → done/failed → archived)
2. **Agent Registry** — Monitor agent status, skills, activity, and usage
3. **Activity Logging** — Track all agent actions for auditability and debugging
4. **Usage Tracking** — Monitor API costs, token consumption, and task throughput per agent
5. **Error Capture** — Structured error logging with backtrace and context

## Core Principle

Agents are autonomous but accountable. Every action is logged, every task is tracked, and every cost is measured. McRitchie Studio is the single source of truth for what's happening across the system.

## Agents

Personas live at `docs/agents/agents/<slug>/{role.md, soul.md}`. The DB registry is seeded from `db/seeds/02_agents.rb` and skills from `db/seeds/03_skills.rb`.

### Leadership
- **Alex** — Lead orchestrator. Coordinates agents, manages priorities, makes architectural calls, escalates when human judgment is needed.
- **Avi** — Product Owner. Reviews PRs, tickets, and release candidates; signs off before Steffon ships.

### Dev specialists
- **Carl** — Backend / Rails. Controllers, models, migrations, jobs, studio-engine internals.
- **Shannon** — UI. ERB views, Tailwind, Alpine.js, theme system, studio-engine UI primitives.
- **Jasper** — Blockchain. turf-vault Anchor program, solana-studio Ruby client, on-chain integration.
- **Steffon** — Infrastructure / DevOps. Heroku, deploys, env vars, CI, observability, recovery protocol.

### Domain & operations
- **Turf Monster** — Sports specialist. Sports data, pick'em games, World Cup props, player analytics.
- **Mack** — General worker. Data scraping, processing, API integrations, bulk operations.
- **Mason** — Marketing. Brand voice, launch comms, social, funnels, copy. (Previously Infrastructure; that surface moved to Steffon.)

## Agent stack flow

```
Alex (orchestration)
  └─> Avi (PO / review)
        ├─> Carl   (backend)
        ├─> Shannon (UI)
        ├─> Jasper (blockchain)
        ├─> Turf Monster (sports domain)
        └─> Mack   (general / data)
              └─> Steffon (deploy + ops)
              └─> Mason   (announce + funnel)
```

Devs build → Avi reviews → Steffon deploys → Mason announces.
