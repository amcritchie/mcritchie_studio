# Branding & Theme

> **When to read this:** Editing colors, navbar, stage badges, the button system, or anything visual. Pair with `studio/CLAUDE.md` theme section for engine-level details.

## Configuration

- **Theme**: Dynamic — engine-generated CSS custom properties from 7 role colors
- **Theme config**: Uses all Studio defaults (violet primary `#8E82FE`). No `theme_*` overrides in `studio.rb`.
- **Admin theme page**: `/admin/theme` — color editor + styleguide (from engine)
- **Primary**: `#8E82FE` Violet — CTAs, buttons, links, hovers, form focus. Views use `text-primary`, `bg-primary`, `bg-primary-700` etc. (dynamic Tailwind palette from CSS vars, not hardcoded violet).
- **Success accent**: `#4BAF50` Green (default) — flash notices, success toasts, active status dots
- **Font**: Montserrat (weights 400-900)
- **Logo**: SVG icon (`app/assets/images/logo-icon.svg`) + "McRitchie **Studio**" (Studio in violet)

## Navbar

Custom navbar in `application.html.erb` (not engine partial). Sticky, scroll-responsive. `sticky top-0 z-50 bg-page` with Alpine `scrolled` state (triggers at 20px). On scroll: logo shrinks `w-8→w-5`, title `text-2xl→text-base`, padding `py-6→py-2`, adds `shadow-lg border-b border-subtle`. All transitions 300ms. Desktop nav: "Meet the Agents 🦞" link. Mobile sub-navbar with same link + gear/moon icons (logged out only). Logged in: renders `_user_nav` with `show_logout_link: true`. Logged out: gear/moon (desktop only) + "Say Hi 👋" button. Admin gear dropdown has: Dashboard, Agents, Tasks, News, Turf Monster (SSO), Tax Studio (SSO), Docs, Theme, Toast Test, Schema, Error Logs.

## Token Usage Rules

- **Surfaces**: Use `bg-page`, `bg-surface`, `bg-surface-alt`, `bg-inset` — never hardcode `bg-navy-*`
- **Text**: Use `text-heading`, `text-body`, `text-secondary`, `text-muted` — never hardcode `text-white` for headings or `text-gray-*` for body text
- **Borders**: Use `border-subtle`, `border-strong` — never hardcode `border-navy-*`
- **CSS var naming**: `--color-cta` / `--color-cta-hover` for singular CTA color. Full `--color-primary-{50..900}` palette with RGB variants for Tailwind `primary-*` utilities.
- **Tailwind config**: `config/tailwind.config.js` dynamically loads studio engine's shared config (`const studioColors = require(\`${studioPath}/tailwind/studio.tailwind.config.js\`)`). Safelists `primary-{50..900}` × `bg/text/border` × opacity variants to ensure compilation.

## Stage Badge Palette

Both News and Content badges now resolve to the shared engine palette introduced 2026-05-17 (Tier 1 #2 of `ecosystem-audit-2026-05-17`). The badge component (`_badge.html.erb` in the engine) accepts these stage-* schemes:

| Scheme | Color | First seen on |
|--------|-------|---------------|
| `stage-fresh` | blue | News.new / Content.idea |
| `stage-shaping` | yellow | News.reviewed / Content.hook |
| `stage-structured` | mint | News.processed / Content.script |
| `stage-refined` | emerald | News.refined / Content.assets |
| `stage-cohered` | violet | News.concluded / Content.assembly |
| `stage-shipped` | emerald | Content.posted |
| `stage-closed` | gray | News.archived / Content.reviewed |

Task stage badges use the existing scheme names (blue=new, yellow=queued, mint=in_progress, green=done, red=failed, gray=archived) — Task is a workflow, not a pipeline, and isn't in the shared palette.

## Button System

`.btn` base + `.btn-primary` (uses `--color-cta`), `.btn-secondary` (uses `--color-success`), `.btn-outline` (hover uses `--color-cta`), `.btn-danger` (uses `--color-danger`), `.btn-google` (white, hardcoded `color: #374151` for dark mode compat). Size: `.btn-sm`, `.btn-lg`.
