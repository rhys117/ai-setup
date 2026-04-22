# ResourceAdapter Reference

The `ResourceAdapter` base class provides a DSL for defining strong parameters, CSV columns, and JSON attributes in a centralized location.

## Location

Adapters live in `app/adapters/` directory.

## DSL Reference

### param_key

Sets the key used to extract params from the request.

```ruby
# By default, derived from adapter name:
# GuestAdapter -> :guest

# Override when model name differs:
class GuestAdapter < ResourceAdapter
  param_key :participant  # params[:participant]
end
```

### permit

Defines strong parameters for mass assignment.

```ruby
class VendorAdapter < ResourceAdapter
  permit :name, :email, :phone,
    tag_ids: [],
    address_attributes: [:id, :street, :city]
end
```

### csv block

```ruby
class VendorAdapter < ResourceAdapter
  csv do
    # Simple columns
    columns :id, :name, :email

    # Custom header and computed value
    column :created_at, header: 'Created' do |vendor|
      vendor.created_at&.strftime('%Y-%m-%d')
    end
  end
end
```

### json block

```ruby
class VendorAdapter < ResourceAdapter
  json do
    # Simple attributes
    attributes :id, :name, :email

    # Computed value
    attribute :created_at do |vendor|
      vendor.created_at&.iso8601
    end

    # Shorthand
    attribute :active, &:active?
  end
end
```

### table block

Define table structure for auto-generated index tables. See `table-dsl-reference.md` for complete documentation.

```ruby
class VendorAdapter < ResourceAdapter
  table do
    title 'Vendors'
    icon :building
    frame_id 'vendors_table'
    row_url { |vendor| app_vendor_path(vendor) }
    empty_state title: 'No vendors yet', description: 'Add vendors to get started.', icon: :building

    column :name, header: 'Name', sortable: true, filter_type: :search, type: :header
    column :email, sortable: true, filter_type: :search
    column :total_amount, header: 'Total', sortable: true, render: :currency

    actions do
      action :new, label: 'New Vendor', variant: :primary, href: -> { new_app_vendor_path }, icon: :plus
    end
  end
end
```

When table definitions exist, `ResourceManagement` auto-generates the index component.

### Dynamic Columns with `columns_from`

For adapters that need to create columns dynamically (e.g., based on database records), use `columns_from` within the `csv` block:

```ruby
class QuestionnaireParticipantAdapter < ResourceAdapter
  class_attribute :questions, default: []

  csv do
    column :name, header: 'Name', &:full_name
    column :plus_one_of, header: 'Plus one of' do |participant|
      participant.owning_participant&.full_name
    end

    # Dynamic columns resolved at runtime from the :questions collection
    columns_from :questions,
                 name: ->(q) { q.id },
                 header: ->(q) { q.query } do |question, participant|
      participant.response_value_for(question: question)
    end
  end

  class << self
    def for_questionnaire(questionnaire)
      self.questions = questionnaire.questions.order(:id).to_a
      self
    end
  end
end
```

**`columns_from` options:**
- `source_method` - Symbol for class method/attribute returning the collection
- `name:` - Lambda to derive column name from each item (default: `&:id`)
- `header:` - Lambda to derive header from each item (default: `&:to_s`)
- Block receives `|item, resource|` and returns the cell value

### Dynamic Attributes with `attributes_from`

The same pattern works for JSON with `attributes_from`:

```ruby
json do
  attributes :id, :name

  attributes_from :questions,
                  key: ->(q) { q.id.to_sym } do |question, participant|
    participant.response_value_for(question: question)
  end
end
```

**`attributes_from` options:**
- `source_method` - Symbol for class method/attribute returning the collection
- `key:` - Lambda to derive attribute key from each item (default: `&:id`)
- Block receives `|item, resource|` and returns the attribute value

## Default Adapter

When no adapter class exists (e.g., no `AccommodationInformationAdapter`), `configure_resource` auto-generates one via `ResourceAdapter.default_for_model(model)`. The default adapter introspects the model's columns and provides:

- **Strong params**: all display columns (excludes `id`, `created_at`, `updated_at`, and `_id` foreign keys)
- **Form**: text inputs for each display column, with type inference (email, phone, number, boolean, date, text_area)
- **Show**: all non-system columns as fields
- **Index table**: all non-text columns with sorting and filters
- **CSV/JSON exports**: all display columns

This is sufficient for simple models. Only create a custom adapter when you need custom labels, placeholders, computed columns, or non-standard behaviour.

```ruby
# No adapter needed — default is auto-generated from model columns
configure_resource model: AccommodationInformation

# Equivalent to manually creating:
class AccommodationInformationAdapter < ResourceAdapter
  permit :description, :url

  form do
    title "Accommodation Information"
    input :description  # inferred as :text
    input :url          # inferred as :text
  end
end
```

## Usage in Controllers

```ruby
class App::VendorsController < App::BaseController
  include CRUDResource

  configure_resource model: Vendor, adapter: VendorAdapter
end
```

The adapter is automatically used for:
- `resource_params` via `adapter_class.permitted_params(params)`
- JSON responses via `adapter.to_json_hash`
- CSV exports via `adapter.to_csv_row`
- Index table via `UI.resource_table` (when table DSL is defined)
- Form via `UI.resource_form` (when form DSL is defined)
