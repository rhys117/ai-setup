---
name: write-tests
description: Write RSpec tests following project conventions. Use when asked to write tests, add specs, or test new/existing features. Covers model, request, system, adapter, service, and job specs.
---

# Write Tests Skill

Write RSpec tests that follow this project's established patterns for data setup, structure, and conventions.

## Running Tests

```bash
# Single file or focused test
bundle exec rspec spec/path/to/spec.rb

# Entire suite (parallelised)
bundle exec parallel_rspec
```

## Data Setup: FixtureKit + Fabrication

This project uses two complementary approaches for test data. Choose the right one for the situation.

### FixtureKit (preferred for specs needing rich, interconnected data)

FixtureKit pre-builds and caches object graphs. Use it when a spec needs an event with participants, activities, questionnaires, etc. — the common "wedding" scenario.

**Available fixtures** (in `spec/fixture_kit/`):

| Fixture | Exposes | Use when |
|---|---|---|
| `base_event` | `organisation`, `event` | Minimal event context |
| `base_event_with_user` | `organisation`, `user`, `event` | Need a signed-in user + event |
| `event_with_participant` | `organisation`, `event`, `participant` | Single participant scenarios |
| `wedding_with_participants` | `organisation`, `default_user`, `event`, `ceremony_activity`, `reception_activity`, `ceremony_questionnaire`, `reception_questionnaire`, `song_request_question`, `participant`, `participant_with_a_plus_one`, `participant_with_two_plus_ones` | Full wedding scenario |

**Using fixtures via shared contexts:**

```ruby
# Full wedding setup — includes ParticipantSpecHelpers
include_context 'Wedding with participants'

# Simpler setups — use fixture directly
let(:fixture_data) { fixture 'base_event_with_user' }
let!(:organisation) { fixture_data.organisation }
let!(:user) { fixture_data.user }
let!(:event) { fixture_data.event }
```

The `'Wedding with participants'` shared context (defined in `spec/support/wedding_contexts.rb`) is the most common — it loads the fixture and exposes all variables as `let!` bindings. It also includes `ParticipantSpecHelpers`.

### Fabrication (for isolated tests or custom object states)

Use `Fabricate` when you need a specific object configuration that doesn't match a fixture, or when testing in isolation (e.g., adapter specs with no DB).

```ruby
# Basic
participant = Fabricate(:participant, event:)

# Variants (defined with `from:`)
participant = Fabricate(:participant_with_a_plus_one, event:)

# Build without saving
activity = Fabricate.build(:activity, address: nil)

# Multiple
communications = Fabricate.times(3, :communication, event:)

# Transient attributes
event = Fabricate(:event, questionnaire: false, primary_activity: custom_activity)
```

Key fabricators to know: `:event`, `:activity`, `:participant`, `:organisation`, `:user`, `:questionnaire`, `:question`, `:answer`, `:communication`, `:mass_communication`, `:import`, `:shared_photo`, `:vendor`, `:group`. Check `spec/fabricators/` for full list and available variants.

### When to create a new FixtureKit fixture

Create a new fixture when:
- Multiple spec files need the same complex object graph
- The setup involves 5+ interconnected objects
- The fixture can be named after a meaningful domain scenario

```ruby
# spec/fixture_kit/my_scenario.rb
FixtureKit.define do
  organisation = Fabricate(:organisation, events: [])
  user = Fabricate(:user, organisation:)
  event = Fabricate(:event, organisation:, activities: [])
  # ... build up the scenario ...

  expose(organisation:, user:, event:)
end
```

Then create a shared context in `spec/support/` to expose the fixture variables.

## Spec Structure by Type

### Model Specs (`spec/models/`)

```ruby
require 'rails_helper'

RSpec.describe MyModel do
  include_context 'Wedding with participants'

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to belong_to(:event) }
  end

  describe '#my_method' do
    it 'does the thing' do
      result = participant.my_method
      expect(result).to eq(expected_value)
    end
  end
end
```

- Use shoulda-matchers for validation/association one-liners
- Use fixture context for methods that depend on related objects
- Use `Fabricate.build` for pure unit tests that don't need persistence

### Request Specs (`spec/requests/`)

```ruby
require 'rails_helper'

RSpec.describe App::MyResourcesController do
  fixture 'base_event_with_user'

  let!(:organisation) { fixture.organisation }
  let!(:user) { fixture.user }
  let!(:event) { fixture.event }

  before { sign_in user }

  describe 'GET #index' do
    it 'returns success' do
      get app_my_resources_path(event)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    let(:valid_params) { { my_resource: { name: 'Test' } } }

    it 'creates the resource' do
      expect {
        post app_my_resources_path(event), params: valid_params
      }.to change(MyResource, :count).by(1)
    end

    context 'with invalid params' do
      it 'does not create the resource' do
        expect {
          post app_my_resources_path(event), params: { my_resource: { name: '' } }
        }.to_not change(MyResource, :count)
      end
    end
  end

  context 'when not signed in' do
    before { sign_out user }

    it 'redirects to login' do
      get app_my_resources_path(event)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
```

- Always test auth (signed in vs. not)
- Test `change { Model.count }` for create/destroy
- Test turbo_stream responses separately if the controller uses them
- Use `response.parsed_body` for JSON assertions

### System Specs (`spec/system/`)

```ruby
require 'rails_helper'

RSpec.describe 'Feature name', type: :system do
  include_context 'Wedding with participants'

  let!(:user) { default_user }

  before { sign_in user }

  it 'allows user to do the thing' do
    visit app_my_resource_path(event)

    within '#section-id' do
      click_link 'Edit'
    end

    fill_in 'Name', with: 'Updated Name'
    click_button 'Save'

    expect(page).to have_content('Updated Name')
  end
end
```

- Tagged `:system` (inferred from file location) — auto-retries 3 times
- Use `within` to scope interactions to specific DOM areas
- Use `have_content`, `have_css`, `have_selector` for assertions
- Use `ActionView::RecordIdentifier.dom_id(object, :prefix)` for dynamic DOM IDs
- System specs run headless Chrome; set `FOREGROUND=1` to see the browser

### Adapter Specs (`spec/adapters/`)

```ruby
require 'rails_helper'

RSpec.describe MyResourceAdapter do
  describe '.permitted_params' do
    it 'permits expected attributes' do
      params = ActionController::Parameters.new(
        my_resource: { name: 'Test', email: 'test@example.com' }
      )
      result = described_class.permitted_params(params)
      expect(result).to include('name' => 'Test', 'email' => 'test@example.com')
    end
  end
end
```

- Pure unit tests — no DB needed
- Use `ActionController::Parameters.new(...)` for param input
- Test coercion, filtering, edge cases (blank values, nested params)

### Service Specs (`spec/services/`)

```ruby
require 'rails_helper'

RSpec.describe MyService do
  include_context 'Wedding with participants'

  describe '#call' do
    it 'performs the operation' do
      service = described_class.new(event:)
      result = service.call

      expect(result).to be_success
    end

    it 'enqueues background work' do
      expect {
        described_class.new(event:).call
      }.to have_enqueued_job(MyJob)
    end
  end
end
```

- Mock external APIs with WebMock stubs
- Test state changes on persisted records
- Test job enqueuing with `have_enqueued_job`

### Job Specs (`spec/jobs/`)

```ruby
require 'rails_helper'

RSpec.describe MyJob do
  include_context 'Wedding with participants'

  describe '#perform' do
    it 'processes the work' do
      described_class.perform_now(participant.id)
      expect(participant.reload.status).to eq('processed')
    end
  end
end
```

## Conventions & Patterns

### Negation
Use `to_not` (not `not_to`) — configured via `RSpec/NotToNot`.

### External APIs
All external HTTP is blocked by WebMock. Stub what you need:

```ruby
stub_request(:post, 'https://api.example.com/endpoint').
  to_return(status: 200, body: '{"ok": true}', headers: { 'Content-Type' => 'application/json' })
```

These are already stubbed globally (in `spec/support/event_webmocking.rb`):
- BetterStack logging
- PostHog event ingestion
- Slack message posting

### Email validation
MX validation is stubbed globally to return `true`. To test invalid emails:

```ruby
allow(ValidEmail2::Address).to receive(:new).and_wrap_original do |method, *args|
  instance = method.call(*args)
  allow(instance).to receive(:valid_mx?).and_return(false)
  instance
end
```

### ActiveJob
Jobs use `:test` adapter. Queues are cleared before each test. Assert with:

```ruby
expect { action }.to have_enqueued_job(MyJob).with(expected_args)
```

### ActionMailer
Deliveries are cleared before each test. Assert with:

```ruby
expect { action }.to change { ActionMailer::Base.deliveries.count }.by(1)
```

### Devise auth
Included automatically for `type: :request` and `type: :system`:

```ruby
sign_in user
sign_out user
```

### ParticipantSpecHelpers
Available when using participant-related shared contexts:

```ruby
answer_all_attending_questions!(participant)  # Auto-answer questionnaire attending questions
populate_plus_ones!(participant)              # Create allowed plus-ones with Faker data
populate_participant_details!(participant)    # Set mobile/email with Faker data
```

### Parallel testing
Tests run in parallel via `parallel_tests`. Each worker gets its own DB (suffixed with `TEST_ENV_NUMBER`) and its own FixtureKit cache directory. No special handling needed in specs.

## Checklist

When writing tests:

- [ ] Choose the right data setup: FixtureKit shared context for rich scenarios, `Fabricate` for isolated/custom objects
- [ ] Place the spec in the correct directory (`spec/models/`, `spec/requests/`, `spec/system/`, etc.)
- [ ] Test the happy path and meaningful edge cases
- [ ] Test authorization (signed in / not signed in / different user)
- [ ] Stub external HTTP calls that aren't already globally stubbed
- [ ] Use `to_not` for negation
- [ ] Use shoulda-matchers for validation/association one-liners
- [ ] Run `bundle exec rspec spec/path/to/spec.rb` to verify specs pass
