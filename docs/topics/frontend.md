# Frontend (JS Modules + AI Chat)

> **When to read this:** Adding/modifying JS modules, importmap entries, Alpine components, the chat UI, or the landing page.

## JS Modules (importmap)

- `kanban_board` — drag-and-drop task board with optimistic DOM moves, API transitions, toast notifications. Race-condition guard (`_pendingMoves`) prevents concurrent API calls for same task. Attached to `window.kanbanBoard` for Alpine `x-data` access.
- `dropping_text` — animated text effect on landing page. Tracks timer IDs and cleans up on `turbo:before-cache` to prevent memory leaks.
- `alex_chat` — Alpine.js `alexChat()` component for AI chat UI. Handles message sending via POST `/chat`, loading states, auto-scroll, basic markdown formatting. HTML-escape happens before markdown transforms (XSS-safe). Attached to `window.alexChat`.
- `depth_chart` — Alpine `depthChart(reorderUrl)` component for `/teams/:slug/depth-chart`. Wires SortableJS per position (drag-reorder, locked rows filter out), calls reorder/toggle_lock endpoints. Attached to `window.depthChart`.

## AI Chat (Alex Agent)

Public-facing chat interface powered by Claude API. Users can chat with an AI Alex persona.

### Architecture
- **ChatController** — `index` renders chat page, `create` accepts JSON `{ message }` and returns `{ response }`. Conversation history stored in `session[:chat_messages]` (last 10 messages).
- **Chat::AlexResponder** — Service using raw `Net::HTTP` to Claude API. Alex McRitchie persona system prompt. Model: `claude-haiku-4-5-20251001`, max tokens: 1024.
- **Chat widget partial** — `chat/_chat_widget.html.erb` accepts `compact:` local (true for landing page card, false for full `/chat` page). Used in both locations.
- **Alpine.js component** — `alexChat()` in `alex_chat.js` handles message state, fetch to `/chat`, loading indicators, auto-scroll, basic markdown rendering.

### Landing Page
- **Hero** — Denver skyline background with Ken Burns pan animation (15s linear), dark overlay for text contrast.
- **Get in Touch section** — Two cards: "Chat Over Video" (Sprintful inline widget embed via `on.sprintful.com`) and "Chat Right Now" (embedded chat widget).
- **Sprintful widget** — Uses official inline widget JS (`app.sprintful.com/widget/v1.js`), not iframe (public URL blocks iframes via X-Frame-Options).
