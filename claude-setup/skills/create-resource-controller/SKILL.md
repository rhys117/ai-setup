---
name: create-resource-controller
description: Create a Rails controller using the CRUDResource concern pattern. Use when the user asks to create a controller, scaffold a resource, or set up CRUD operations.
---

# Create Resource Controller Skill

Generate Rails controllers that leverage the ResourceManagement concern pattern with adapters for serialization, strong params, and export functionality.

## Architecture Overview

ResourceManagement is decomposed into focused concerns:

```
ResourceManagement
├── Configuration  - configure_resource, configure_views
├── DataAccess     - resource, build_resource, collection, resource_params
├── Authorization  - Pundit policy scoping
├── Actions        - enable/disable CRUD actions
├── Routes         - path helpers
├── CRUD           - index, show, new, create, edit, update, destroy
└── ResponseHandling (included automatically)
```

## Core Principles

1. **Adapters centralize resource concerns**: Strong params, JSON serialization, and CSV exports are defined in adapter classes
2. **Use hooks, not action overrides**: Leverage `before_create`, `after_create`, `before_update`, `after_update`, `before_persist` for business logic
3. **Customize paths, not rendering**: Control redirect behavior through `resource_path`, `edit_resource_path`, `collection_path`
4. **Let defaults work**: Only override CRUD actions when hooks and paths can't accomplish the goal

## Instructions

When the user requests to create a controller:

### 1. Gather Requirements

Ask the user:
- What model/resource is this controller for?
- What scope should be applied? (e.g., current_user, organization, event)
- Are there any custom actions beyond standard CRUD?
- What attributes should be permitted for create/update?
- Does the model use a custom identifier? (e.g., uuid instead of id)
- What data should be exported in CSV/JSON formats?

### 2. Create the Adapter (or use the default)

**If no adapter class exists**, `configure_resource` auto-generates a default adapter from the model's column metadata. The default adapter provides:
- Strong params for all display columns (excludes `id`, `created_at`, `updated_at`, foreign keys)
- A form with text inputs inferred from column types
- A show page with all non-system columns
- An index table with sortable/filterable columns
- CSV and JSON exports

This is often sufficient for simple models. Skip to step 3 if the default works.

**For custom behavior**, create an explicit adapter. The adapter defines:
- Strong parameters via `permit`
- CSV columns via `csv_columns` and `csv_column`
- JSON attributes via `json_attributes` and `json_attribute`
- Custom `param_key` if needed

```ruby
# app/adapters/resource_adapter.rb (base class already exists)
# app/adapters/my_resource_adapter.rb

class MyResourceAdapter < ResourceAdapter
  # If the param key differs from the adapter name (e.g., :participant instead of :guest)
  param_key :custom_key

  # Strong parameters - used by resource_params in controller
  permit :name, :email, :status,
    nested_ids: [],
    nested_attributes: [:id, :field1, :field2]

  # CSV configuration
  csv do
    # Simple columns
    columns :id, :name, :email, :status, :created_at

    # Columns with custom headers or computed values
    column :related_items, header: 'Related Items' do |resource|
      resource.items.pluck(:name).join(', ')
    end

    column :formatted_date, header: 'Created' do |resource|
      resource.created_at&.strftime('%Y-%m-%d %H:%M')
    end
  end

  # JSON configuration
  json do
    # Simple attributes
    attributes :id, :name, :email, :status

    # Attributes with computed values
    attribute :related_items do |resource|
      resource.items.map { |i| {id: i.id, name: i.name} }
    end

    attribute :created_at do |resource|
      resource.created_at&.iso8601
    end
  end

  # Helper methods for formatting (accessible in csv/json blocks)
  class << self
    private

    def format_boolean(value)
      value ? 'Yes' : 'No'
    end
  end
end
```

### 3. Create the Controller

```ruby

class NamespaceOrScope::ResourcesController < App::BaseController
  include CRUDResource

  # Configure the resource with model, adapter, and optional settings
  configure_resource(
    model: ResourceModel,
    adapter: MyResourceAdapter,
    order: { created_at: :desc }, # Default ordering
    id_field: :id # Use :uuid if model uses UUID
  )

  # Configure view components
  configure_views(
    index_component: -> {
      NamespaceOrScope::Resource::TableComponent.new(
        resources: collection
      )
    },
    show_component: -> { NamespaceOrScope::Resource::ShowComponent.new(resource: resource) },
    form_component: -> { NamespaceOrScope::Resource::FormComponent.new(resource: resource) }
  )

  # Optionally limit available actions
  # actions only: [:index, :show, :new, :create]
  # actions except: [:destroy]

  private

  # Lifecycle hooks
  def before_create(resource)
    resource.user = current_user
    resource
  end
end
```

### 4. Lifecycle Hooks Reference

**`before_create(resource)`** - Called before saving a new resource
```ruby
def before_create(resource)
  resource.user = current_user
  resource.status = 'pending'
  resource
end
```

**`before_update(resource)`** - Called before saving an existing resource
```ruby
def before_update(resource)
  resource.last_modified_by = current_user
  resource
end
```

**`before_persist(resource)`** - Called by both before_create and before_update
```ruby
def before_persist(resource)
  resource.normalized_name = resource.name.downcase
  resource
end
```

**`after_create`** - Called after successful create
```ruby
def after_create
  NotificationService.notify_created(resource)
end
```

**`after_update`** - Called after successful update
```ruby
def after_update
  resource.mark_as_reviewed!
end
```

**`before_destroy(resource)`** - Called before destroying
```ruby
def before_destroy(resource)
  resource.archive_related_records!
  resource
end
```

### 5. Path Resolution

**Paths are auto-resolved from `controller_path`.** The `RouteResolver` converts the controller path into route helpers automatically:

| Controller path | collection_path | resource_path |
|---|---|---|
| `app/vendors` | `app_vendors_path` | `app_vendor_path(resource)` |
| `app/settings/accommodation_informations` | `app_settings_accommodation_informations_path` | `app_settings_accommodation_information_path(resource)` |

You only need to override path methods for custom redirect behaviour:

```ruby
# Stay on edit page after create (for review workflows)
def resource_path
  if @resource&.persisted? && @resource.pending?
    edit_resource_path
  else
    super
  end
end

# Return to collection after update
def resource_path
  collection_path
end
```

### 5a. Embedded Resources (`embedded_in`)

When a resource doesn't have its own pages and lives inside another page (e.g., a settings panel, a parent show page), use `embedded_in`:

```ruby
embedded_in path: -> { app_settings_path(anchor: "accommodation") },
            turbo_frame: -> { helpers.dom_id(event, :accommodation_form) }
```

- **`path:`** (required) — proc returning the host page URL. Replaces `collection_path`, `resource_path`, `edit_resource_path`, and `after_destroy_path` with a single declaration.
- **`turbo_frame:`** (optional) — proc returning the turbo frame ID for inline form rendering. When provided, auto-registers a `before_action` that sets `@turbo_frame_id` and `@replace_target` on new/create/edit/update actions. The default `ResourceFormComponent` picks up `@turbo_frame_id` and wraps the form in the specified frame instead of `dom_id(resource, "form")`.

Both procs receive controller instance context, so route helpers and dynamic params work. Individual path methods remain overridable if one needs to diverge.

The host page's show component must wrap its content in a matching turbo frame for the swap to work.

### 6. Custom Actions

For actions beyond CRUD, use ResponseHandling methods:

```ruby
def approve
  resource.approve!(current_user)

  render_for resource,
    path: resource_path,
    message: "#{resource.name} has been approved",
    component: show_component,
    html_redirects: true
rescue StandardError => e
  render_errors resource,
    message: "Approval failed: #{e.message}",
    replace_component: show_component
end
```

### 7. Actions DSL

Limit which CRUD actions are available:

```ruby
# Only allow read operations
actions only: [:index, :show]

# Allow everything except destroy
actions except: [:destroy]

# Custom actions are always allowed (not filtered)
```

## Format Handling

ResourceManagement automatically handles multiple formats via ResponseHandling:

- **HTML**: Renders ViewComponent or redirects
- **Turbo Stream**: Updates DOM and shows flash messages
- **JSON**: Uses adapter's `json_attributes` for serialization
- **CSV**: Uses adapter's `csv_columns` for streaming export

### CSV Export

CSV export is automatic for index actions when an adapter is configured:

```bash
# Request CSV
GET /app/resources.csv
```

For custom CSV exports (outside ResourceManagement):

```ruby
def show
  respond_to do |format|
    format.html { ... }
    format.csv do
      stream_csv(resource.items, adapter: ItemAdapter, filename: "items-#{resource.id}.csv")
    end
  end
end
```

### JSON API

JSON responses include:

```json
// Single resource
{"data": {"id": 1, "name": "...", ...}}

// Collection (paginated)
{
  "data": [...],
  "meta": {
    "total_count": 100,
    "total_pages": 4,
    "current_page": 1,
    "per_page": 25
  }
}
```

## Anti-Patterns to Avoid

❌ **Don't define strong params in controller when using adapter:**
```ruby
# BAD - adapter handles this
def resource_params
  params.require(:resource).permit(:name, :email)
end
```

✅ **Do define permit in adapter:**
```ruby
# GOOD - centralized in adapter
class MyResourceAdapter < ResourceAdapter
  permit :name, :email
end
```

❌ **Don't override actions unnecessarily:**
```ruby
# BAD - reimplementing what CRUDResource does
def create
  @resource = build_resource
  if @resource.save
    redirect_to @resource
  else
    render :new
  end
end
```

✅ **Do use hooks:**
```ruby
# GOOD - let CRUDResource handle rendering
def before_create(resource)
  resource.user = current_user
  resource
end
```

❌ **Don't manually handle rendering in hooks:**
```ruby
# BAD - hooks should not render
def after_create
  redirect_to resource_path
end
```

## Testing

Create RSpec request specs for the controller:

```ruby
require 'rails_helper'

RSpec.describe NamespaceOrScope::ResourcesController do
  let(:user) { Fabricate(:user) }
  let(:resource) { Fabricate(:resource, user: user) }

  before { sign_in user }

  describe 'GET #index' do
    it 'returns HTML by default' do
      get namespace_scope_resources_path
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('text/html')
    end

    context 'with CSV format' do
      it 'returns a CSV file' do
        get namespace_scope_resources_path(format: :csv)
        expect(response.headers['Content-Type']).to include('text/csv')
        expect(response.headers['Content-Disposition']).to include('attachment')
      end
    end

    context 'with JSON format' do
      it 'returns JSON with data array' do
        get namespace_scope_resources_path(format: :json)
        json = response.parsed_body
        expect(json).to have_key('data')
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) { {resource: {name: 'Test'}} }

    it 'creates a new resource' do
      expect {
        post namespace_scope_resources_path, params: valid_params
      }.to change(Resource, :count).by(1)
    end
  end

  describe 'PATCH #update' do
    it 'updates the resource' do
      patch namespace_scope_resource_path(resource), params: {
        resource: {name: 'Updated'}
      }
      expect(resource.reload.name).to eq('Updated')
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the resource' do
      resource # create it
      expect {
        delete namespace_scope_resource_path(resource)
      }.to change(Resource, :count).by(-1)
    end
  end
end
```

## Examples

See the resources directory for complete examples:
- `guests-example.md` - Clean adapter-based controller with custom id_field
- `imports-example.md` - File upload workflow with hooks and custom actions
- `table-dsl-reference.md` - Adapter table DSL for auto-generated index tables
- `embedded-resource-example.md` - Resource embedded inline in a settings page using `embedded_in` and `@turbo_frame_id`

## Summary Checklist

When creating a ResourceManagement controller:

- [ ] Create adapter class with `permit`, `csv do ... end`, `json do ... end` — or use the default adapter for simple models
- [ ] **Optional**: Add `table do ... end` block for auto-generated index table
- [ ] Include `CRUDResource` concern in controller
- [ ] Configure resource with `configure_resource(model:, adapter:, ...)`
- [ ] Configure views with `configure_views(...)` (skip `index_component` if using table DSL)
- [ ] **Optional**: Add `configure_scopes(...)` for filterable scope tabs
- [ ] **Optional**: Use `embedded_in path:, turbo_frame:` if resource lives inside another page
- [ ] Override path methods only if custom redirect behaviour is needed (paths are auto-resolved from `controller_path`)
- [ ] Add lifecycle hooks (`before_create`, `after_create`, etc.) as needed
- [ ] Use `actions only:/except:` to limit available actions if needed
- [ ] Add custom actions using `render_for` and `render_errors`
- [ ] Write comprehensive RSpec request specs covering all formats
