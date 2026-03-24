# Memory System

## Shared Memory

The shared memory file at `docs/agents/shared/MEMORY.md` is accessible to all agents. Use it for:
- Cross-agent coordination notes
- System-wide status updates
- Shared discoveries and patterns

## Agent-Specific Memory

Each agent maintains its own memory via Claude Code's auto-memory system at `~/.claude/projects/*/memory/MEMORY.md`. Agent-specific memory includes:
- Task context and progress notes
- Learned patterns from repeated operations
- Environment-specific configuration

## What to Remember
- Stable patterns confirmed across multiple interactions
- Key architectural decisions and file paths
- Solutions to recurring problems
- User preferences for workflow and communication

## What NOT to Remember
- Session-specific context (current task details, temporary state)
- Unverified conclusions from reading a single file
- Anything that duplicates CLAUDE.md instructions
