# News Pipeline

> **When to read this:** Adding/modifying News services or agents, debugging the intake/review/process/refine/conclude flow, or adjusting the AI-call shape.

`app/services/news/` contains 5 service classes + 3 AI agents (reopening the `News` class, not a module). Services take a News record, accept a fields hash, update fields, and advance the stage. AI agents call Claude API to generate the fields, then delegate to the corresponding service.

## Services + Agents

- **`News::Intake`** — Fetches latest Adam Schefter tweets from X API v2. Requires `X_BEARER_TOKEN` in `.env`. Creates News with `stage: "new"`. Deduplicates by `x_post_id`. Rake: `bin/rails news:intake`.
- **`News::Review`** (Mason) — Sets primary/secondary person/team/action + article_image_url → `review!`
- **`News::ReviewAgent`** — Claude Haiku extracts people/teams/action from tweet text → delegates to `News::Review`. Rake: `bin/rails news:review`.
- **`News::Process`** (Mack) — Generates slugs via `parameterize`, find-or-creates Person/Team records, creates Contract associations → `process_news!`. Tracks `created_records` array reporting whether each Person/Team was `created`, `found`, or `not_found`. Rake: `bin/rails news:process` (outputs `[+]` created, `[=]` found, `[?]` not_found).
- **`News::Refine`** (Alex) — Sets title_short (3-5 words), summary, feeling, feeling_emoji, what_happened → `refine!`
- **`News::RefineAgent`** — Claude Haiku generates refined summary fields from tweet + review context → delegates to `News::Refine`. Rake: `bin/rails news:refine`.
- **`News::Conclude`** (Turf Monster) — Sets opinion, callback → `conclude!`
- **`News::ConcludeAgent`** — Claude Haiku generates editorial opinion + callback action → delegates to `News::Conclude`. Rake: `bin/rails news:conclude`.

## Pipeline Invocation

- **Full pipeline**: `bin/rails news:intake news:review news:process news:refine news:conclude`
- **SLUG= override**: All rake tasks accept `SLUG=news-abc123` to target a specific article instead of picking the next one.
- **Agent ordering**: All `*_latest` methods use `position: :desc` to pick the top-of-kanban (highest position) article first.

## News → Content Bridge

`NewsController#create_content` creates a Content (stage: idea) linked to a concluded News article via `source_news_slug`. Button on News show page when stage == "concluded".

## Pipeline Progression UI

Shared partial `app/views/shared/_pipeline_progression.html.erb` shows unified 12-step pipeline across News (1-6) and Content (7-12), with archived as a side step from concluded. Accepts `highlight:` param ("news" or "content") to dim the non-active pipeline. Rendered on both index pages.

## Kanban Column Focus

Click column header to expand that column full-width (hides others). Click again to unfocus. Alpine `focusedStage` state with `toggleFocus()` method. Both News and Content boards.

## People Search

`PeopleController#search` JSON endpoint with ILIKE matching on first_name, last_name, slug, and aliases. Used by News edit sidebar for verifying Person records during news processing.
