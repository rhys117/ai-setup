# GuestsController Reference Example

This is the **recommended pattern** for most controllers. It demonstrates a clean adapter-based ResourceManagement controller with multi-format support (HTML, JSON, CSV).

## Overview

The GuestsController manages participants (aliased as "guests" in the UI). It demonstrates:
- Adapter-based strong params, JSON, and CSV serialization
- Custom `id_field` for UUID-based routing
- Custom `param_key` when model name differs from controller name
- Simple lifecycle hook for setting associations
- Clean, minimal controller code

## The Adapter

```ruby
# app/adapters/guest_adapter.rb

class GuestAdapter < ResourceAdapter
  # The model is Participant but params come as :participant
  param_key :participant

  # Strong parameters - used by DataAccess#resource_params
  permit :first_name, :last_name, :email, :mobile, :age_category, :allowed_plus_ones,
    group_ids: [],
    responses_attributes: [:id, :question_id, :answer_id, :value],
    plus_ones_attributes: [:id, {responses_attributes: [:id, :question_id, :answer_id, :value]}]

  # CSV configuration
  csv do
    # Simple columns
    columns :uuid, :first_name, :last_name, :full_name, :email, :mobile, :age_category

    # Columns with custom headers and computed values
    column :groups, header: 'Groups' do |participant|
      participant.groups.pluck(:name).join(', ')
    end

    column :attending_event, header: 'Attending Event' do |participant|
      format_boolean(participant.attending_event?)
    end

    column :declined_all, header: 'Declined All' do |participant|
      format_boolean(participant.declined_all?)
    end

    column :plus_ones_count, header: 'Plus Ones' do |participant|
      participant.plus_ones.count
    end

    column :created_at, header: 'Created' do |participant|
      participant.created_at&.strftime('%Y-%m-%d %H:%M')
    end
  end

  # JSON configuration
  json do
    # Simple attributes
    attributes :uuid, :full_name, :first_name, :last_name, :email, :mobile, :age_category,
               :allowed_plus_ones, :declined_all

    # Attributes with computed values
    attribute :groups do |participant|
      participant.groups.map { |g| {id: g.id, name: g.name} }
    end

    attribute :attending_event, &:attending_event?

    attribute :plus_ones_count do |participant|
      participant.plus_ones.count
    end

    attribute :created_at do |participant|
      participant.created_at&.iso8601
    end

    attribute :updated_at do |participant|
      participant.updated_at&.iso8601
    end
  end

  # Helper methods (accessible in csv/json blocks)
  class << self
    private

    def format_boolean(value)
      value ? 'Yes' : 'No'
    end
  end
end
```

## The Controller

```ruby
# app/controllers/app/guests_controller.rb

class App::GuestsController < App::BaseController
  include CRUDResource

  before_action :process_new_groups, only: [:create, :update]

  configure_resource model: Participant, id_field: :uuid, adapter: GuestAdapter
  configure_views(
    index_component: -> {
      App::Guest::TableComponent.new(
        user: current_user,
        event: event
      )
    },
    show_component: -> { App::Guest::ShowComponent.new(participant: resource) },
    form_component: -> { App::Guest::FormComponent.new(participant: resource) },
  )

  private

  def collection_path
    app_guests_path
  end

  def resource_path
    app_guest_path(resource.uuid)
  end

  def edit_resource_path
    edit_app_guest_path(resource.uuid)
  end

  def before_create(resource)
    resource.event = event
    resource
  end

  def process_new_groups
    return unless params[:participant][:new_group_names].present?

    groups = Group::EnsureFromList.do(
      params[:participant][:new_group_names],
      event: event,
    )

    params[:participant][:group_ids] = groups.map(&:id).concat(params[:participant][:group_ids])
  end
end
```

## Key Patterns

### 1. Adapter Configuration

The adapter handles three concerns:
1. **Strong params**: `permit` defines what attributes can be mass-assigned
2. **CSV export**: `csv do ... end` block defines export format
3. **JSON API**: `json do ... end` block defines API response

### 2. Custom param_key

When the controller name differs from the model name:
```ruby
# Controller is GuestsController, but model is Participant
# Form fields use params[:participant]
param_key :participant
```

### 3. Custom id_field

When the model uses UUID instead of numeric ID:
```ruby
configure_resource model: Participant, id_field: :uuid, adapter: GuestAdapter
```

This changes `DataAccess#resource` to find by UUID:
```ruby
# Instead of: collection.find_by!(id: params[:id])
# Uses:       collection.find_by!(uuid: params[:id])
```

### 4. Path Helpers for Custom ID

When using UUID, paths need the UUID value:
```ruby
def resource_path
  app_guest_path(resource.uuid)
end

def edit_resource_path
  edit_app_guest_path(resource.uuid)
end
```

### 5. Minimal before_create

Just sets the event association:
```ruby
def before_create(resource)
  resource.event = event
  resource
end
```

### 6. before_action for Complex Preprocessing

When you need to modify params before ResourceManagement processes them:
```ruby
before_action :process_new_groups, only: [:create, :update]

def process_new_groups
  return unless params[:participant][:new_group_names].present?

  groups = Group::EnsureFromList.do(
    params[:participant][:new_group_names],
    event: event,
  )

  params[:participant][:group_ids] = groups.map(&:id).concat(params[:participant][:group_ids])
end
```

## Multi-Format Support

With an adapter configured, the controller automatically supports:

### HTML (default)
```
GET /app/guests
GET /app/guests/:uuid
```

### JSON API
```
GET /app/guests.json
GET /app/guests/:uuid.json
```

Response:
```json
{
  "data": [
    {
      "uuid": "abc-123",
      "full_name": "John Doe",
      "groups": [{"id": 1, "name": "Family"}],
      "attending_event": true,
      ...
    }
  ],
  "meta": {
    "total_count": 50,
    "total_pages": 2,
    "current_page": 1,
    "per_page": 25
  }
}
```

### CSV Export
```
GET /app/guests.csv
```

Response (streamed):
```csv
Uuid,First name,Last name,Full name,Email,Mobile,Age category,Groups,Attending Event,Declined All,Plus Ones,Created
abc-123,John,Doe,John Doe,john@example.com,0400000000,adult,Family,Yes,No,2,2024-01-15 10:30
```

## Testing

```ruby
require 'rails_helper'
require 'support/wedding_contexts'

RSpec.describe App::GuestsController do
  include_context 'Wedding with participants'

  before { sign_in default_user }

  describe 'GET #index' do
    it 'returns HTML by default' do
      get app_guests_path
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('text/html')
    end

    context 'with CSV format' do
      it 'returns a CSV file with correct headers' do
        get app_guests_path(format: :csv)
        expect(response.headers['Content-Type']).to include('text/csv')
        expect(response.headers['Content-Disposition']).to include('attachment')
        expect(response.body).to include('Uuid,First name,Last name')
      end
    end

    context 'with JSON format' do
      it 'returns JSON with data array and uses adapter serialization' do
        get app_guests_path(format: :json)
        json = response.parsed_body
        expect(json).to have_key('data')
        expect(json['data'].first).to have_key('full_name')
        expect(json['data'].first).to have_key('groups')
      end
    end
  end

  describe 'GET #show' do
    context 'with JSON format' do
      it 'returns JSON with adapter attributes' do
        get app_guest_path(participant.uuid, format: :json)
        json = response.parsed_body
        expect(json['data']['uuid']).to eq(participant.uuid)
        expect(json['data']).to have_key('attending_event')
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        participant: {
          first_name: 'New',
          last_name: 'Guest',
          email: 'new@example.com',
          mobile: '0400000000',
          age_category: 'adult'
        }
      }
    end

    it 'creates a new participant' do
      expect {
        post app_guests_path, params: valid_params
      }.to change(Participant, :count).by(1)
    end

    it 'associates participant with current event' do
      post app_guests_path, params: valid_params
      expect(Participant.last.event).to eq(event)
    end
  end

  describe 'PATCH #update' do
    it 'updates the participant' do
      patch app_guest_path(participant.uuid), params: {
        participant: {first_name: 'Updated'}
      }
      expect(participant.reload.first_name).to eq('Updated')
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the participant' do
      expect {
        delete app_guest_path(participant.uuid)
      }.to change(Participant, :count).by(-1)
    end
  end
end
```

## Key Takeaways

1. **Adapter centralizes concerns**: Strong params, JSON, and CSV all in one place
2. **Controller stays minimal**: Just configuration and hooks
3. **Multi-format support is automatic**: Once adapter is configured, CSV/JSON work out of the box
4. **Custom identifiers need path overrides**: When using UUID, override path helpers
5. **Use before_action for param preprocessing**: Complex param transformations before ResourceManagement
