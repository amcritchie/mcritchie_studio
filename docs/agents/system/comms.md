# Communication Protocol

## Agent-to-Studio Communication

All agents communicate with McRitchie Studio via the JSON API at `/api/v1/`.

### Claiming a Task
1. `GET /api/v1/tasks?stage=queued&agent_slug=AGENT` — Check for assigned queued tasks
2. `POST /api/v1/tasks/:slug/start` — Claim and start the task
3. Do the work
4. `POST /api/v1/tasks/:slug/complete` — Report success with result data
5. OR `POST /api/v1/tasks/:slug/fail_task` — Report failure with error message

### Logging Activity
After significant actions, agents should log activity:
```json
POST /api/v1/activities
{
  "agent_slug": "mack",
  "activity_type": "task_completed",
  "description": "Scraped 72 match odds from FiveThirtyEight",
  "task_slug": "task-abc123"
}
```

### Reporting Usage
At end of work sessions, agents report costs:
```json
POST /api/v1/usages
{
  "agent_slug": "mack",
  "period_date": "2026-03-23",
  "period_type": "daily",
  "model": "claude-opus-4-6",
  "tokens_in": 50000,
  "tokens_out": 12000,
  "api_calls": 15,
  "cost": 1.2500
}
```

### Updating Status
Agents can update their own status:
```json
PATCH /api/v1/agents/mack
{ "status": "paused" }
```

## Activity Types
- `task_started` / `task_completed` / `task_failed`
- `task_assigned`
- `deployment`
- `data_sync`
- `system_check`
- `error`
