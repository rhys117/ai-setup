# RSpec Testing Framework Guidelines

## 1. Initial Setup

### 1.1 Required Gems
```ruby
group :test do
  gem "rspec-rails"      # Testing framework
  gem "vcr"              # Record and replay HTTP interactions
  gem "webmock"          # HTTP request stubbing
  gem "fabrication"      # Test data generation
  gem "database_cleaner" # Clean test database between runs
  gem "shoulda-matchers" # RSpec matchers for Rails
end
```

### 1.2 VCR Configuration
```ruby
# spec/support/vcr.rb
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }
  config.allow_http_connections_when_no_cassette = false
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
end
```

### 1.3 RSpec Configuration
```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  # Database cleaner setup
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Fabrication setup
  config.include Fabrication::Syntax::Methods
  
  # Metadata filters setup
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  
  # Randomize test order
  config.order = :random
  Kernel.srand config.seed
end
```

## 2. Test Structure Best Practices

### 2.1 Describe/Context/It Pattern
```ruby
RSpec.describe User, type: :model do
  # Describe defines the subject under test
  describe "validations" do
    # Context groups similar test cases
    context "when creating a new user" do
      # Individual test cases
      it "requires an email" do
        user = User.new(email: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end
      
      it "requires a unique email" do
        Fabricate(:user, email: "test@example.com")
        user = User.new(email: "test@example.com")
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("has already been taken")
      end
    end
  end
end
```

### 2.2 Metadata Usage
```ruby
# Tag tests with metadata to control behavior
RSpec.describe ApiClient, :vcr do
  # Will use VCR for HTTP requests

  it "performs slow operations", :slow do
    # Will be skipped with --tag ~slow
  end
  
  it "tests external API", :external do
    # Will be skipped in CI with proper config
  end
end
```

### 2.3 Subject & Let Definitions
```ruby
RSpec.describe Order do
  # Define reusable test data with let
  let(:user) { Fabricate(:user) }
  let(:product) { Fabricate(:product, price: 10.00) }
  
  # Define the subject under test
  subject(:order) { Fabricate(:order, user: user, items: [item]) }
  let(:item) { Fabricate(:order_item, product: product, quantity: 2) }
  
  it "calculates the total correctly" do
    expect(order.total).to eq(20.00)
  end
end
```

## 3. Testing API Interactions

### 3.1 Service Testing with VCR
```ruby
RSpec.describe ApiService, :vcr do
  describe "#fetch_data" do
    context "when API is available" do
      it "returns expected data", vcr: { cassette_name: "api_service/fetch_data_success" } do
        service = ApiService.new
        response = service.fetch_data
        expect(response).to include(expected_data)
      end
    end

    context "when API is unavailable" do
      before do
        stub_request(:get, /api\.example\.com/).
          to_return(status: 503)
      end

      it "handles the error gracefully" do
        service = ApiService.new
        expect { service.fetch_data }.
          to raise_error(ApiService::ServiceUnavailable)
      end
    end
  end
end
```

### 3.2 VCR Best Practices

#### 3.2.1 Cassette Management
1. Name cassettes descriptively: `"#{service_name}/#{action}_#{scenario}"`
2. Use separate cassettes for different test scenarios
3. Re-record cassettes periodically to catch API changes
4. Filter sensitive data (API keys, tokens)

#### 3.2.2 Recording Options
```ruby
# Record new interactions, but play back existing ones
it "fetches data", vcr: { record: :new_episodes } do
  # test code
end

# Always use new recordings
it "fetches data", vcr: { record: :all } do
  # test code
end

# Never make real HTTP requests
it "fetches data", vcr: { record: :none } do
  # test code
end
```

## 4. Testing Service Objects or Operations

### 4.1 Testing Service Objects
```ruby
RSpec.describe ApiService do
  describe "#fetch_data" do
    let(:client) { instance_double("ApiClient") }
    let(:service) { described_class.new(client) }
    
    context "with successful response" do
      let(:response) { instance_double("Response", status: 200, body: '{"key":"value"}') }
      
      before do
        allow(client).to receive(:get).and_return(response)
      end
      
      it "returns parsed JSON" do
        expect(service.fetch_data).to eq({"key" => "value"})
      end
    end
    
    context "with API errors" do
      let(:response) { instance_double("Response", status: 503) }
      
      before do
        allow(client).to receive(:get).and_return(response)
      end
      
      it "raises ServiceUnavailable error" do
        expect { service.fetch_data }.to raise_error(ApiService::ServiceUnavailable)
      end
    end
  end
end
```

## 5. Error Handling in Tests

### 5.1 Exception Testing
```ruby
it "raises an appropriate error" do
  expect { service.fetch_data }.to raise_error(ApiService::Error)
end

it "raises a specific error with message" do
  expect { service.fetch_data }.to raise_error(
    ApiService::ResourceNotFound, 
    "Resource not found"
  )
end

it "doesn't raise an error" do
  expect { service.fetch_data }.not_to raise_error
end
```

### 5.2 Testing Recovery Procedures
```ruby
describe "#fetch_with_fallback" do
  context "when primary source fails" do
    before do
      allow(service).to receive(:fetch_from_primary).and_raise(ApiService::Error)
    end
    
    it "uses fallback source" do
      expect(service).to receive(:fetch_from_fallback)
      service.fetch_with_fallback
    end
  end
end
```

## 6. Continuous Integration Testing

### 6.1 CI Configuration Guidelines
```yaml
# .gitlab-ci.yml or .github/workflows/rspec.yml
test:
  script:
    # Set up test environment
    - export RAILS_ENV=test
    - bundle install --jobs $(nproc) --retry 3
    # Run tests
    - bundle exec rspec --format documentation
    # Optional: Generate coverage report 
    - bundle exec rspec --format documentation --format RspecJunitFormatter --out rspec.xml
  artifacts:
    paths:
      - coverage/
      - rspec.xml
  variables:
    VCR_RECORD_MODE: none  # Prevent real API calls in CI
```

### 6.2 Environment Variables
```yaml
# .env.test
API_KEY=test_key
API_ENDPOINT=https://api.example.com
VCR_RECORD_MODE=none
```

### 6.3 Test Isolation
1. Run tests in random order (`--order random`)
2. Avoid dependencies between tests
3. Reset database and global state between tests
4. Use unique test data to prevent interference

## 7. Debugging Test Failures

### 7.1 Techniques
1. Use `--fail-fast` to stop at first failure
2. Focus on specific tests with `--tag focus`
3. Use `save_and_open_page` with Capybara
4. Print debugging with `puts` or `pp`

### 7.2 Common Issues
1. Time-dependent failures (freeze time in tests)
2. Order-dependent failures (improve isolation)
3. VCR cassette incompatibilities (re-record)
4. Database state leakage (ensure proper cleanup)