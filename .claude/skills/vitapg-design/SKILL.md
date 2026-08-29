---
name: vitapg-design
description: VitaPG design system — aesthetic direction, tokens, component rules, and the anti-AI-slop checklist. Load before writing or changing any UI (components, views, layouts, Tailwind).
---

# VitaPG Design System

VitaPG is an operations dashboard: people open it to verify their business continuity is safe. The design context is **operate** (not persuade). Every screen must answer "is everything OK, and if not, what and where?" at a glance.

## The world: "Control Room"

One committed aesthetic, applied end-to-end. Calm, technical, precise — the visual language of well-built infrastructure tools (think Kamal/37signals product pages, Linear's density, Postgres documentation sobriety).

- **Ground**: near-white warm gray (`--color-surface`), content on white cards with hairline borders (`1px`, low-contrast). No shadows heavier than `shadow-sm`. Dark mode is a first-class variant of the same system.
- **Accent**: a single desaturated steel blue derived from the PostgreSQL brand (`#336791` family). Used ONLY for primary actions and active navigation. Everything else is neutral.
- **Status is semantic and never decorative**: green = completed, red = failed, amber = warning/degraded, blue = running, gray = disabled/pending. Status appears as a small solid dot + text label, never a pulsing dot, never a colored card background.
- **Typography**: `Inter` (via Google Fonts) with system-ui fallback. Data tables and metrics use `tabular-nums`. Technical values — cron expressions, hostnames, file sizes, SQL identifiers, keys — always render in mono (`font-mono text-[0.8125rem]`). Headings are `font-semibold`, never bold+italic serif, max two heading sizes per screen.
- **Density**: compact and information-rich. Tables over card grids for lists. 8px spacing grid; generous only around page titles.
- **Motion**: none beyond Turbo's defaults and 150ms color/opacity transitions on interactive elements.

## Tokens

All theme values are defined once in `app/assets/stylesheets/application.tailwind.css` under `@theme` (Tailwind 4). Components consume tokens via utility classes; never hardcode hex values in templates.

## Rules

1. **Inherit the system.** New UI reuses existing ViewComponents and tokens. If a pattern doesn't exist yet, add it as a component, not inline markup.
2. **One accent.** If a screen has two competing accent-colored elements, one is wrong.
3. **Specific words.** Buttons and headings name the action/object ("Run backup now", "3 routines"), never vague copy ("Get started", "Manage"). All copy through i18n.
4. **No AI tells**: no emoji in UI copy or headings, no gradient text/backgrounds, no glassmorphism, no purple-violet default palettes, no "cards in cards", no side-tab borders, no italic serif display type, no pulsing dots, no rounded-3xl blobs, no centered hero layouts inside the app.
5. **Empty states teach.** Every index screen has an empty state explaining what the object is and one primary action to create it.
6. **Errors are content.** Failed runs and error logs get full-width, readable treatment (mono, wrapped, copyable) — not a red toast.
7. **Accessibility**: WCAG AA contrast, visible focus rings (`focus-visible:ring-2`), every icon-only button has an aria-label (i18n'd), forms use real `<label>`s, tables have proper `<th scope>`.
8. **No dark patterns.** Destructive actions (delete routine, prune backups) require explicit confirmation naming the object; never preselect destructive options; cancel is always as easy as confirm.
9. **Numbers respect the reader**: file sizes humanized (`142.3 MB`), durations humanized (`2m 14s`), timestamps in the user's timezone with absolute value on hover when shown relative.

## Component conventions

- Buttons: `ButtonComponent` variants `:primary` (accent, one per view region), `:secondary` (neutral outline), `:danger` (red, only for destructive), `:ghost`.
- Status: `StatusBadgeComponent` is the only way to render a run/routine status.
- Layout: sidebar navigation (workspace switcher top, nav middle, user bottom) + content area with a `PageHeaderComponent` (title, description, primary action).
- Forms: `FormFieldComponent` wraps label + input + hint + error; secrets use masked write-only inputs.
