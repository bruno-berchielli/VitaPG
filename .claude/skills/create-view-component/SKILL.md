---
name: create-view-component
description: Conventions for building ViewComponents with sidecar templates, auto-registered Stimulus controllers, per-component i18n, and Tailwind 4 styling. Load before creating or editing anything in app/components.
---

# Create View Component

All UI is built from ViewComponents in `app/components`, organized by namespace. Styling lives in the component template with Tailwind utilities consuming `@theme` tokens — never in application CSS.

## Sidecar layout

```
app/components/<namespace>/<name>_component.rb
app/components/<namespace>/<name>_component/
  ├── <name>_component.html.erb
  ├── <name>_component_controller.js   (only when JS behavior is needed)
  └── <name>_component.yml             (only when the component has translatable text)
```

Generate with: `bin/rails generate view_component:component Namespace::Name attr --sidecar` (generator is configured for sidecar + locale + stimulus). Delete the generated `.js` stub if the component needs no behavior, and the `.yml` if it has no text.

## Base class

Every component extends `ApplicationComponent`, which provides `dom_id`, Turbo helpers, and the Stimulus naming helpers. **Never hardcode Stimulus controller identifiers** — derive them:

```ruby
stimulus_controller        # => "backup_runs--log-viewer-component--log-viewer-component"
data_stimulus_controller   # => 'data-controller=...'
data_stimulus("target", "list") # => 'data-<controller>-target=list'
```

## JS autoload

Component controllers are auto-registered by the glob import in `app/components/index.js` (via the `esbuild-rails` plugin): every `*_controller.js` under `app/components/**` becomes a Stimulus controller named after its path (`backup_runs/log_viewer_component/log_viewer_component_controller.js` → `backup-runs--log-viewer-component--log-viewer-component`). Zero manual wiring — just create the file.

```js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["list"];

  connect() {}
}
```

## i18n

Component `.yml` sidecars are on the i18n load path. Include all three locales, use relative lookup in templates:

```yaml
en:
  backup_runs:
    log_viewer_component:
      empty: "No log entries yet"
pt-BR:
  backup_runs:
    log_viewer_component:
      empty: "Ainda não há entradas de log"
es:
  backup_runs:
    log_viewer_component:
      empty: "Aún no hay entradas de registro"
```

```erb
<%= t(".empty") %>
```

## Rules

- Skinny templates: computed classes, conditionals, and data live in the `.rb` file as methods.
- Accept `**html_attributes` passthrough on generic/wrapper components.
- Follow `.claude/skills/vitapg-design` for visual decisions.
- Live-updating components follow `.claude/skills/create-self-refreshing-component`.
