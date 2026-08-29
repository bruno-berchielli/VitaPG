---
name: vitapg-design
description: VitaPG design system ("Vision") — aesthetic direction, tokens, component rules, and the anti-AI-slop checklist. Load before writing or changing any UI (components, views, layouts, Tailwind).
---

# VitaPG Design System — "Vision"

VitaPG is an operations dashboard: people open it to verify their business continuity is safe. The design context is **operate** (not persuade). Every screen must answer "is everything OK, and if not, what and where?" at a glance.

## The world

Aesthetic ported from the Vision Marketing Dashboard kit (ui8, dpopstudio): deep glossy blacks over cool light grays, generous rounded geometry, huge friendly numerals. One committed system, applied end-to-end.

- **Typography**: **Quicksand** (600/700) for headings, big numerals and display text (`font-display`); **Inter** for body and data (`font-sans`, `tabular-nums` on numbers); mono only for technical values (cron, hosts, keys).
- **Surfaces**: light theme = cool gray page (`--c-bg #edeff4`) with **white borderless cards** (`rounded-card` = 24px, `shadow-soft`); dark theme = near-black page with charcoal cards. No visible card borders — separation comes from background contrast and soft shadow.
- **Hero surfaces**: the signature element. Glossy near-black cards (`.hero-card`, radial speculars over `--c-hero`) carry the welcome header, key stats (label in 11px uppercase tracking-[0.18em], value in Quicksand 3xl–5xl bold) and the donut gauge (thick white ring, `Ui::GaugeComponent`). Hero cards stay black in BOTH themes.
- **Ink actions**: the primary button is an "ink" **pill** (`rounded-full`): black with white text on light, white with black text on dark (`bg-ink text-on-ink`). On hero surfaces use the white pill (`variant: :hero`). Secondary = outlined pill; small table actions = mini ink pills.
- **Status chips**: filled rounded-lg chips with white text — mint `#3ec9a7` success, coral `#fd6c64` danger, amber `#f5b544` warning, violet `#6e62e5` running/info; muted gray for neutral. Rendered only via `Ui::StatusBadgeComponent`.
- **Sidebar**: floating rounded-card white/charcoal panel with margin around it; logo dot-mark; tiny uppercase section labels ("Operations" / "Workspace"); **active item = full ink pill**; light/dark segmented toggle and user card at the bottom.
- **Topbar**: pill search field (global search) + date chip, both floating on the page background.
- **Forms**: filled inputs (`bg-surface-highlight`, `rounded-xl`, borderless, `focus:ring-ink`), semibold labels, hints in muted 12px. Secrets are write-only.
- **Tables**: inside borderless cards; thead in 11px uppercase tracking; rows separated by hairline `border-t`; avatar circles for people; row primary action = mini ink pill.
- **Density & motion**: airy (24px card padding), 8px grid; no motion beyond Turbo defaults and 150ms color/opacity transitions.

## Tokens

All theme values live in `app/assets/stylesheets/application.postcss.css` under `@theme` (semantic `--color-*` mapped from raw `--c-*` palettes for light and `[data-mode="dark"]`). Components consume tokens via utilities; never hardcode hex in templates. `data-mode` lives on `<body>` (Turbo replaces body, not html).

## Rules

1. **Inherit the system.** New UI reuses existing ViewComponents and tokens. If a pattern doesn't exist yet, add it as a component, not inline markup.
2. **One hero moment per screen.** Black hero cards are for the screen's headline facts; everything else sits on white/charcoal cards.
3. **Specific words.** Buttons and headings name the action/object ("Run backup now", "3 routines"), never vague copy. All copy through i18n (en/pt-BR/es).
4. **No AI tells**: no gradient text, no glassmorphism, no purple-default palettes, no cards-in-cards, no pulsing dots, no emoji headers (the single 👋 in the welcome hero is the kit's own signature and the one exception).
5. **Empty states teach.** Every index has an empty state with what the object is and one primary action.
6. **Errors are content.** Failed runs get full-width readable treatment (mono, wrapped, copyable) — not a toast.
7. **Accessibility**: WCAG AA contrast, visible focus rings (`focus-visible:ring-2 ring-ink`), aria-labels on icon-only buttons, real `<label>`s, `<th scope>`.
8. **No dark patterns.** Destructive actions require explicit confirmation naming the object; cancel is as easy as confirm.
9. **Numbers respect the reader**: humanized sizes/durations, relative timestamps with absolute on hover, `tabular-nums`.

## Component inventory

`Ui::ButtonComponent` (primary/secondary/danger/ghost/hero pills) · `Ui::CardComponent` · `Ui::HeroStatComponent` · `Ui::GaugeComponent` · `Ui::StatusBadgeComponent` · `Ui::PageHeaderComponent` · `Ui::EmptyStateComponent` · `Ui::FlashComponent` (ink pill toast) · `Ui::IconComponent` · `Ui::CopyButtonComponent` · `Layout::SidebarComponent` · `Layout::TopbarComponent`.
