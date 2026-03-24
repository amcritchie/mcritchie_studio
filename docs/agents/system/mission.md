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

- **Alex** — Lead orchestrator. Coordinates all agents, manages priorities, reviews output.
- **Mack** — General worker. Handles data scraping, processing, and bulk operations.
- **Mason** — Infrastructure specialist. Deployments, monitoring, database management.
- **Turf Monster** — Domain specialist. Sports data, pick'em games, player analytics.
