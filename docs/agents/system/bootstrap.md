# Bootstrap

## First-Time Setup

```bash
cd mcritchie_studio
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

Visit `http://localhost:3000` — dashboard shows 4 agents, task pipeline, activity feed.

## Login

- Email: `alex@mcritchie.studio`
- Password: `pass`

## Google OAuth (optional)

Set environment variables:
```bash
export GOOGLE_CLIENT_ID=your_client_id
export GOOGLE_CLIENT_SECRET=your_client_secret
```

## Re-seeding

Seeds are idempotent (`find_or_create_by!`) — safe to re-run anytime:
```bash
bin/rails db:seed
```

## API Quick Test

```bash
# List agents
curl http://localhost:3000/api/v1/agents

# Create a task
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Test task", "agent_slug": "mack", "priority": 0}'

# Start a task
curl -X POST http://localhost:3000/api/v1/tasks/SLUG/start
```
