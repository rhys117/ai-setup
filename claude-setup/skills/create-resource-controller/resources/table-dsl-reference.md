# Adapter Table DSL Reference

The `ResourceAdapter` table DSL allows you to define table columns, configuration, and actions directly in the adapter, eliminating the need for custom table components.

## Overview

When an adapter has table definitions, `ResourceManagement` automatically generates the index table using `UI::DataDisplay::ResourceTableComponent`. You don't need to create a custom table component.

## DSL Reference

### table block

All table configuration is nested within a single `table do ... end` block:

```ruby
class GuestAdapter < ResourceAdapter
  table do
    # Configuration
    title 'Guests'
    icon :users
    frame_id 'guests_table'
    row_url { |guest| app_guest_path(guest.uuid) }
    empty_state title: 'No guests yet', description: '...', icon: :users

    # Columns
    column :email, sortable: true, filter_type: :search

    # Actions
    actions do
      action :new, label: 'New Guest', variant: :primary, href: -> { new_app_guest_path }, icon: :plus
    end

    # Nested rows
    nested_rows :plus_ones, order: :name_ordered, prefix: '+'
  end
end
```

### column

Defines the columns displayed in the table. Called within the `table` block.

```ruby
class GuestAdapter < ResourceAdapter
  table do
    # Simple attribute column
    column :email, sortable: true, filter_type: :search

    # Column with all options
    column :full_name,
           header: 'Name',           # Display header (default: humanized name)
           sortable: true,           # Enable sorting
           filter_type: :search,     # :search, :select, or nil
           type: :header,            # :default, :header (bold), :status
           render: :text,            # :text, :badges, :currency, :boolean
           max_width: 'xs',          # Tailwind max-width class
           data_key: 'name'          # Key used for sorting (default: column name)

    # Column with custom block for computed values
    column(:plus_ones_display, header: 'Plus Ones', sortable: true, data_key: 'plus_ones') do |participant|
      "#{participant.plus_ones.count} / #{participant.allowed_plus_ones}"
    end

    # Badges for array values
    column(:groups, header: 'Tags', render: :badges) do |participant|
      participant.groups.map(&:name)
    end

    # Currency formatting
    column :total_amount, header: 'Total', sortable: true, render: :currency
  end
end
```

#### Column Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `header` | String | Humanized name | Column header text |
| `sortable` | Boolean | false | Enable column sorting |
| `filter_type` | Symbol | nil | `:search` or `:select` |
| `filter_options` | Array | nil | Options for select filter |
| `type` | Symbol | `:default` | Cell type: `:default`, `:header`, `:status` |
| `render` | Symbol | `:text` | Renderer: `:text`, `:badges`, `:currency`, `:boolean` |
| `max_width` | String | nil | Tailwind max-width class |
| `data_key` | String | column name | Key used for sorting |

#### Render Types

| Type | Description |
|------|-------------|
| `:text` | Plain text, shows "-" for nil |
| `:badges` | Array of `UI.status_badge` components |
| `:currency` | Formatted with `number_to_currency` |
| `:boolean` | Checkmark (✓) or X (✗) |

### Configuration Methods

These methods are called directly within the `table` block:

```ruby
class GuestAdapter < ResourceAdapter
  table do
    title 'Guests'                                    # Table title
    icon :users                                       # Icon type (from UI.icon)
    frame_id 'guests_table'                           # Turbo frame ID
    row_url { |guest| app_guest_path(guest.uuid) }    # Row click URL
    empty_state title: 'No guests yet',
                description: "When you add guests, they'll appear here.",
                icon: :users

    # columns go here...
  end
end
```

#### Config Methods

| Method | Description |
|--------|-------------|
| `title` | String displayed as table header |
| `icon` | Symbol for `UI.icon` component |
| `frame_id` | Turbo frame ID for scoped updates |
| `row_url { \|resource\| }` | Block returning URL for row clicks |
| `empty_state` | Hash with `:title`, `:description`, `:icon` |

### actions block

Defines action buttons in the table header. Nested within the `table` block.

```ruby
class GuestAdapter < ResourceAdapter
  table do
    # config and columns...

    actions do
      action :import,
             label: 'Import From Spreadsheet',
             variant: :secondary,
             href: -> { new_app_import_path },
             icon: :download,
             data: { turbo_frame: '_top' }

      action :new,
             label: 'New Guest',
             variant: :primary,
             href: -> { new_app_guest_path },
             icon: :plus,
             data: { turbo: false }
    end
  end
end
```

#### Action Options

| Option | Type | Description |
|--------|------|-------------|
| `label` | String | Button text |
| `variant` | Symbol | `:primary`, `:secondary` |
| `href` | Proc | Lambda returning the URL (evaluated in controller context) |
| `icon` | Symbol | Icon type (from UI.icon) |
| `data` | Hash | Turbo data attributes |

### nested_rows

Displays nested/child records as indented rows. Called within the `table` block.

```ruby
class GuestAdapter < ResourceAdapter
  table do
    # config and columns...

    nested_rows :plus_ones,          # Association name
                order: :name_ordered, # Scope to apply for ordering
                prefix: '+'           # Badge prefix for nested rows
  end
end
```

## Controller Integration

### Basic Usage (Auto-Generated Table)

When an adapter has table definitions, the index component is auto-generated:

```ruby

class App::GuestsController < App::BaseController
  include CRUDResource

  configure_resource model: Participant, adapter: GuestAdapter
  # No index_component needed - auto-generated from adapter!

  configure_views(
    show_component: -> { App::Guest::ShowComponent.new(participant: resource) },
    form_component: -> { App::Guest::FormComponent.new(participant: resource) }
  )
end
```

### With Scopes

Scopes add filterable tabs to the table. Define them with `configure_scopes`:

```ruby

class App::GuestsController < App::BaseController
  include CRUDResource

  configure_resource model: Participant, adapter: GuestAdapter

  configure_scopes(
    confirmed: ->(collection) { collection.attending_event(event) },
    declined: ->(collection) { collection.declined_event(event) },
    not_responded: ->(collection) { collection.merge(Participant.unopened_or_not_answered(event)) }
  )
end
```

Scopes appear as tabs: **All** | **Confirmed** | **Declined** | **Not Responded**

Each scope is a lambda that receives the base collection and returns a filtered collection.

### Path Helpers

The component needs a `collection_path` method for scope navigation:

```ruby
def collection_path
  app_guests_path
end
```

## Complete Example

### Adapter

```ruby
class VendorAdapter < ResourceAdapter
  table do
    title 'Vendors'
    icon :building
    frame_id 'vendors_table'
    row_url { |vendor| app_vendor_path(vendor) }
    empty_state title: 'No vendors yet',
                description: "When you add vendors to your event, they'll appear here.",
                icon: :building

    column :name, header: 'Name', sortable: true, filter_type: :search, type: :header
    column :email, sortable: true, filter_type: :search
    column :total_amount, header: 'Total Amount', sortable: true, render: :currency
    column :total_payments, header: 'Amount Paid', sortable: true, render: :currency

    actions do
      action :new, label: 'New Vendor', variant: :primary,
                   href: -> { new_app_vendor_path }, icon: :plus
    end
  end
end
```

### Controller

```ruby

class App::VendorsController < App::BaseController
  include CRUDResource

  configure_resource model: Vendor, adapter: VendorAdapter
  configure_views(
    show_component: -> { App::Vendor::ShowComponent.new(vendor: resource) },
    form_component: -> { App::Vendor::FormComponent.new(vendor: resource) }
  )

  private

  def collection_path
    app_vendors_path
  end

  def resource_path
    app_vendor_path(resource)
  end

  def edit_resource_path
    edit_app_vendor_path(resource)
  end

  def collection
    @collection ||= policy_scope(event.vendors)
  end

  def before_create(resource)
    resource.event = event
    resource
  end
end
```

## Checking for Table Definitions

```ruby
# In code
GuestAdapter.has_table_definition?  # => true if table_columns and table_config are defined

# The auto-generated index_component checks this automatically
```

## Available Icons

Icons available in `UI.icon`:
- `:users`, `:user`
- `:plus`, `:edit`, `:delete`, `:refresh`
- `:download`, `:copy`
- `:check`, `:x`, `:warning`, `:info`
- `:calendar`, `:clock`
- `:envelope`, `:email`, `:message`, `:sms`
- `:heart`, `:clipboard`
- `:map_pin`, `:location`
- `:lock`, `:chevron_right`, `:palette`
- `:help_circle`, `:question`
- `:building` (for vendors/businesses)
