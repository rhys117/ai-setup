# Embedded Resource Example: Accommodation Informations

A resource that lives inline within a settings page rather than having its own standalone pages. Uses the default adapter (no custom adapter class needed), `embedded_in` for path resolution, and `@turbo_frame_id` for inline form rendering.

## Route

```ruby
resource :settings, only: [:show] do
  resources :accommodation_informations, only: [:new, :create, :edit, :update, :destroy],
    controller: 'settings/accommodation_informations'
end
```

No `index` or `show` — the resource is displayed within the settings page's show component.

## Controller

```ruby
class App::Settings::AccommodationInformationsController < App::Settings::BaseController
  include CRUDResource

  actions only: [:new, :create, :edit, :update, :destroy]

  configure_resource model: AccommodationInformation
  configure_views(
    index_component: proc { App::EventConfiguration::AccommodationSection::IndexComponent.new(event: event) }
  )
  embedded_in path: -> { app_settings_path(anchor: "accommodation") },
              turbo_frame: -> { helpers.dom_id(event, :accommodation_form) }

  private

  def before_create(resource)
    resource.event = event
    resource
  end
end
```

### Key patterns

- **No adapter class** — `AccommodationInformation` has simple columns (`description`, `url`), so the default adapter auto-generates the form, strong params, and exports from column metadata.
- **`embedded_in path:`** — replaces `collection_path`, `resource_path`, `edit_resource_path`, and `after_destroy_path` with a single declaration. The proc has controller instance context.
- **`embedded_in turbo_frame:`** — auto-registers a `before_action` that sets `@turbo_frame_id` (tells `ResourceFormComponent` which frame to wrap the form in) and `@replace_target` (tells response handling which frame to replace on success).
- **`index_component`** — renders the accommodation list back into the settings section after create/update. Embedded resources use `index_component` (not `show_component`) because after save we're returning to the list, not viewing a single resource.

## Host page index component

The index component renders the resource list within a `UI.content_section` wrapped in a turbo frame. The turbo frame ID must match what the controller sets.

```ruby
# app/components/app/event_configuration/accommodation_section/index_component.rb
class App::EventConfiguration::AccommodationSection::IndexComponent < ApplicationComponent
  attr_reader :event

  def initialize(event:)
    @event = event
  end

  def accommodations
    event.accommodation_informations
  end
end
```

```erb
<%# app/components/app/event_configuration/accommodation_section/index_component.html.erb %>
<%= render UI.content_section(
  title: "Accommodation",
  description: "Suggested places to stay, included in Save the Date and RSVP emails",
  turbo_frame_id: dom_id(event, :accommodation_form),
  anchor_id: "accommodation"
) do |section| %>
  <% section.with_actions do %>
    <%= render UI.button(
      href: new_app_settings_accommodation_information_path,
      variant: :secondary,
      data: { turbo_frame: dom_id(event, :accommodation_form) }
    ) do |btn| %>
      <% btn.with_icon(type: :plus, size: :xs) %>
      Add
    <% end %>
  <% end %>

  <% if accommodations.any? %>
    <div class="space-y-4">
      <% accommodations.each do |accommodation| %>
        <div class="flex items-center justify-between border-l-2 border-app-primary-200 pl-4">
          <div class="min-w-0">
            <p class="text-sm font-medium text-neutral-900"><%= accommodation.description %></p>
            <% if accommodation.url.present? %>
              <p class="mt-1 text-sm text-neutral-500 truncate"><%= accommodation.url %></p>
            <% end %>
          </div>
          <div class="flex items-center gap-2 ml-4 shrink-0">
            <%= render UI.button(
              href: edit_app_settings_accommodation_information_path(accommodation),
              variant: :ghost,
              data: { turbo_frame: dom_id(event, :accommodation_form) }
            ) do |btn| %>
              <% btn.with_icon(type: :edit, size: :xs) %>
            <% end %>
            <%= render UI.button(
              href: app_settings_accommodation_information_path(accommodation),
              variant: :ghost,
              method: :delete,
              data: { turbo_confirm: "Remove this accommodation?" }
            ) do |btn| %>
              <% btn.with_icon(type: :delete, size: :xs) %>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
  <% else %>
    <p class="text-sm text-neutral-500 italic">No accommodation suggestions have been added yet.</p>
  <% end %>
<% end %>
```

### How the turbo frame flow works

1. Settings page renders `ShowComponent` inside turbo frame `dom_id(event, :accommodation_form)`
2. "Add" / "Edit" buttons target that frame → hit controller `new` / `edit` action
3. Controller sets `@turbo_frame_id` → default `ResourceFormComponent` wraps form in the same frame
4. Form replaces the section content inline
5. On submit success, controller renders `show_component` into `@replace_target` → section swaps back to the list
6. Cancel button targets the same frame and links to `app_settings_path` → reloads the show component

## Adding to the host page

```erb
<%# In the parent settings show component %>
<%= render App::EventConfiguration::AccommodationSection::IndexComponent.new(event: event) %>
```
