# User Guide

## Dashboard

The root page (`/`) shows:
- **Agent cards** — Status, type, and description for all registered agents
- **Task pipeline** — Count of tasks in each stage
- **Recent activity** — Chronological feed of agent actions

## Agents

- `/agents` — Grid view of all agents
- `/agents/:slug` — Agent detail with skills, recent tasks, and activity

## Tasks

- `/tasks` — Filterable list with stage tabs
- `/tasks/new` — Create a new task (requires login)
- `/tasks/:slug` — Task detail with stage transition buttons
- `/tasks/:slug/edit` — Edit task details (requires login)

### Task Stages
1. **New** — Just created, not yet assigned to queue
2. **Queued** — Ready for an agent to pick up
3. **In Progress** — An agent is actively working on it
4. **Done** — Completed successfully
5. **Failed** — Encountered an error (see error message)
6. **Archived** — Removed from active pipeline

## Activity

- `/activities` — Reverse-chronological feed of all agent activity
- Filter by agent or activity type via URL params

## Errors

- `/error_logs` — Recent errors with message, target, and timestamp
- `/error_logs/:id` — Error detail with full backtrace

## Authentication

- Login at `/login` with email/password or Google OAuth
- Signup at `/signup`
- Dashboard and monitoring pages are public
- Task creation/editing requires login
