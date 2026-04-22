---
name: ui-components
description: UI Component System reference. Use when building views, pages, or any frontend template. MUST use UI.* components instead of raw HTML unless explicitly justified.
---

# UI Component System

**ALWAYS use UI components instead of writing raw HTML.** If you need to render a common UI element (panel, card, button, badge, form field, etc.), check the UI library first. Only write raw HTML if no suitable component exists AND the element is too specific to warrant a new component.

This is a hard rule — like `CRUDResource` for controllers. If you bypass the UI system, justify it in the PR.

## Architecture

The UI system uses a mixin pattern. The `UI` class (`app/components/ui.rb`) extends method modules:

```ruby
class UI
  extend UI::Layout::Methods
  extend UI::Nav::Methods
  extend UI::Feedback::Methods
  extend UI::Forms::Methods
  extend UI::Actions::Methods
  extend UI::DataDisplay::Methods
end
```

Each module (e.g., `app/components/ui/layout/methods.rb`) provides helper methods:

```ruby
module UI::Layout::Methods
  def container(**args, &)
    UI::Layout::ContainerComponent.new(**args, &)
  end

  def panel(**args, &)
    UI::Layout::PanelComponent.new(**args, &)
  end
end
```

## Accessing UI Components

Components are accessed via the `UI` class with helper methods:

```ruby
# Correct - use helper methods
UI.container
UI.panel
UI.card
UI.button
UI.status_badge
UI.progress_bar
UI.detail_item

# Wrong - don't instantiate directly
UI::Layout::ContainerComponent.new  # Avoid this
```

## Adding New UI Components

1. Create the component in the appropriate namespace (e.g., `app/components/ui/layout/my_component.rb`)
2. Add a helper method to the corresponding methods module (e.g., `app/components/ui/layout/methods.rb`)
3. Access via `UI.my_component(...)`

## Page Structure Pattern

Pages should follow this structure (see `app/components/app/vendor/show_component.html.erb` for reference):

```erb
<%= render UI.container do %>
  <%= render UI.panel do |panel| %>
    <% panel.with_header(title: "Page Title", description: "Optional description") do |header| %>
      <% header.with_icon do %>
        <!-- Back link or icon -->
      <% end %>
      <% header.with_actions do %>
        <!-- Action buttons, badges -->
      <% end %>
    <% end %>

    <!-- Panel content here -->
  <% end %>
<% end %>
```

## Discovering Available Components

To discover available UI helper methods, check the method modules in `app/components/ui/*/methods.rb`.

## Component Best Practices

1. **Never inline HTML for common UI elements** - Always check if a UI component exists first
2. **Keep logic out of templates** - Put conditionals and formatting in component Ruby files
3. **Use slots** - Components like `panel` and `card` have slots (`with_header`, `with_footer`, `with_icon`, `with_actions`)
4. **Extend the UI system** - If a component is used in multiple places, add it to the UI library with a helper method

## Frontend Conventions

- Use Tailwind CSS for styling (no custom CSS unless necessary)
- Implement interactivity with Alpine.js
- Use Turbo for SPA-like navigation
- Follow BEM naming for custom components

## Color Palette Names

Use these semantic palette names in all Tailwind classes. **Never** use raw color names (e.g. `gray-500`, `rose-600`) for app palette colors.

| Palette | Purpose | Example usage |
|---------|---------|---------------|
| `neutral` | Grays, text, borders, backgrounds | `bg-neutral-100`, `text-neutral-700` |
| `warm` | Warm tones, soft highlights | `bg-warm-50`, `text-warm-600` |
| `app-primary` | Primary brand color | `bg-app-primary-500`, `text-app-primary-700` |
| `app-secondary` | Secondary brand color | `bg-app-secondary-500`, `border-app-secondary-200` |
| `app-accent` | Accent/tertiary color | `bg-app-accent-500`, `text-app-accent-600` |
| `app-danger` | Destructive/error actions | `bg-app-danger-500`, `text-app-danger-700` |
| `warning` | Warning states (Tailwind yellow) | `bg-warning-50`, `text-warning-700` |

- Each palette has shades `50` through `900`
- These are backed by CSS custom properties in `application.tailwind.css`, making palette swaps a single-file change
- **Do not confuse** with dynamic theming classes (`dynamic-primary`, `bg-dynamic-accent`) which are for guest-facing event templates
