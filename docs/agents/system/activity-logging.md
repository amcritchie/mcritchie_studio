# Activity Logging

## Purpose

Every significant agent action should be logged as an Activity record. This provides:
- Audit trail for debugging
- Performance monitoring
- Inter-agent visibility

## How to Log

```json
POST /api/v1/activities
{
  "agent_slug": "mack",
  "activity_type": "task_completed",
  "description": "Scraped 48 team records from FIFA API",
  "task_slug": "task-abc123",
  "metadata": { "records_count": 48, "source": "fifa-api" }
}
```

## Activity Types

| Type | When to Use |
|------|-------------|
| `task_started` | Agent begins work on a task |
| `task_completed` | Task finished successfully |
| `task_failed` | Task encountered an error |
| `task_assigned` | Orchestrator assigns a task |
| `deployment` | Code deployed to an environment |
| `data_sync` | Data synchronized between systems |
| `system_check` | Health check or monitoring sweep |
| `error` | Unexpected error occurred |
| `heartbeat` | Agent reporting it's alive and idle |

## Querying Activities

- `GET /api/v1/activities` — All recent activity
- `GET /api/v1/activities?agent_slug=mack` — Filter by agent
- `GET /api/v1/activities?activity_type=deployment` — Filter by type
