# ImportsController Reference Example

This example demonstrates ResourceManagement with file uploads and custom params handling - a case where you may NOT want to use an adapter.

## When to Skip the Adapter

Use this pattern when:
- Create and update require different params (file upload vs JSON data)
- The resource doesn't need CSV/JSON export via the standard pattern
- Strong params are complex and action-specific

## Overview

The ImportsController handles CSV file uploads for importing participants into events. It demonstrates:
- File upload handling in `build_resource`
- CSV parsing in `before_create` hook
- Custom action (`confirm`) using ResponseHandling methods
- Different params for create vs update (no adapter)

## Full Implementation

```ruby

class App::ImportsController < App::BaseController
  include CRUDResource

  configure_resource model: Import, order: { created_at: :desc }
  configure_views(
    index_component: -> {
      App::Import::TableComponent.new(
        imports: collection,
        event: event
      )
    },
    show_component: -> { App::Import::ShowComponent.new(import: resource, event: event) },
    form_component: -> { App::Import::FormComponent.new(import: resource, event: event) }
  )

  def confirm
    result = ImportService.do(
      import: resource,
      event: event
    )

    resource.update!(
      status: 'confirmed',
      imported_count: result[:imported_count]
    )

    render_for resource,
      path: app_guests_path,
      replace_target: helpers.dom_id(resource, 'form'),
      message: "Successfully imported #{result[:imported_count]} participants",
      component: App::Guest::TableComponent.new(
        user: current_user,
        event: event
      )
  rescue StandardError => e
    resource.mark_as_failed!(e.message)
    render_errors resource, replace_component: form_component, message: "Import failed: #{e.message}"
  end

  private

  def collection
    @collection ||= policy_scope(event.imports)
  end

  def build_resource
    @resource ||= collection.new(# rubocop:disable Naming/MemoizedInstanceVariableName
      event: event,
      user: current_user,
      file_name: import_params[:file]&.original_filename,
      status: 'pending'
    )
  end

  def before_create(resource)
    csv_parser = ImportService::Processors::CSVParser::V1.new(
      event: event,
      csv_content: import_params[:file].read
    )

    participants_data = csv_parser.parse
    resource.parsed_data = {
      'participants' => participants_data[:rows],
      'errors' => participants_data[:errors] || {}
    }
    resource.error_count = participants_data[:errors]&.keys&.length || 0

    resource
  rescue StandardError => e
    resource.errors.add(:base, "Failed to parse CSV: #{e.message}")
    resource
  end

  def after_update
    resource.mark_as_reviewed!
  end

  def collection_path
    app_imports_path
  end

  def resource_path
    app_import_path(resource)
  end

  # Manual resource_params because create vs update need different params
  def resource_params
    params.require(:import).permit(parsed_data: {})
  end

  def import_params
    params.permit(:file)
  end
end
```

## Key Patterns

### 1. No Adapter - Different Params per Action

This controller doesn't use an adapter because:
- Create: Accepts file upload via `import_params`
- Update: Accepts `parsed_data` JSON via `resource_params`

```ruby
# Used by update action (standard resource_params)
def resource_params
  params.require(:import).permit(parsed_data: {})
end

# Used by create action (separate file params)
def import_params
  params.permit(:file)
end
```

### 2. File Upload in build_resource

```ruby
def build_resource
  @resource ||= collection.new(
    event: event,
    user: current_user,
    file_name: import_params[:file]&.original_filename,
    status: 'pending'
  )
end
```

### 3. CSV Parsing with Error Handling

```ruby
def before_create(resource)
  csv_parser = ImportService::Processors::CSVParser::V1.new(
    event: event,
    csv_content: import_params[:file].read
  )

  participants_data = csv_parser.parse
  resource.parsed_data = {
    'participants' => participants_data[:rows],
    'errors' => participants_data[:errors] || {}
  }
  resource.error_count = participants_data[:errors]&.keys&.length || 0

  resource
rescue StandardError => e
  resource.errors.add(:base, "Failed to parse CSV: #{e.message}")
  resource  # Always return resource, even on error
end
```

### 4. Custom Action with render_for

```ruby
def confirm
  result = ImportService.do(import: resource, event: event)

  resource.update!(
    status: 'confirmed',
    imported_count: result[:imported_count]
  )

  render_for resource,
    path: app_guests_path,
    replace_target: helpers.dom_id(resource, 'form'),
    message: "Successfully imported #{result[:imported_count]} participants",
    component: App::Guest::TableComponent.new(user: current_user, event: event)
rescue StandardError => e
  resource.mark_as_failed!(e.message)
  render_errors resource, replace_component: form_component, message: "Import failed: #{e.message}"
end
```

## Workflow Summary

1. **Upload (Create)**:
   - User uploads CSV file
   - `build_resource` creates Import with filename
   - `before_create` parses CSV, validates, stores parsed data
   - Saves Import (even with parse errors stored in error_count)
   - Redirects to show page

2. **Review (Edit/Update)**:
   - User reviews parsed data on edit page
   - Can fix errors in the UI
   - Updates Import with corrected `parsed_data`
   - `after_update` marks as reviewed

3. **Confirm (Custom Action)**:
   - User confirms import
   - `confirm` action runs ImportService
   - Updates status to 'confirmed'
   - Redirects to guests list

## Key Takeaways

1. **Skip adapter when params differ by action**: Manual `resource_params` gives full control
2. **Always return resource from hooks**: Even on error, return the resource for proper error rendering
3. **Use render_for for custom actions**: Handles HTML, Turbo Stream, and JSON consistently
4. **Separate concerns**: File params vs resource params, parsing vs persistence
