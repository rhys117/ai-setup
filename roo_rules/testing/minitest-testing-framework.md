# Minitest Testing Framework Guidelines

## 1. Initial Setup

### 1.1 Required Gems
```ruby
group :test do
  gem "minitest"                   # Testing framework
  gem "minitest-reporters"         # Customizable test outputs
  gem "vcr"                        # Record and replay HTTP interactions
  gem "webmock"                    # HTTP request stubbing
  gem "fabrication"                # Test data generation
  gem "database_cleaner-active_record" # Clean test database between runs
  gem "minitest-rails"             # Rails integration
end
```

### 1.2 VCR Configuration
```ruby
# test/support/vcr.rb
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }
  config.allow_http_connections_when_no_cassette = false
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
end

# Helper module to use in tests
module VCRTestHelper
  def use_vcr_cassette(cassette_name)
    VCR.use_cassette(cassette_name) do
      yield
    end
  end
end
```

### 1.3 Minitest Configuration
```ruby
# test/test_helper.rb
ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"
require "minitest/reporters"
require "webmock/minitest"
require "support/vcr"

# Use pretty reporters
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

# Database Cleaner setup
DatabaseCleaner.strategy = :transaction

class ActiveSupport::TestCase
  # Include Fabrication methods
  include Fabrication::Syntax::Methods
  
  # Include VCR helpers
  include VCRTestHelper
  
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)
  
  # Setup all fixtures in test/fixtures/*.yml
  fixtures :all
  
  # Setup and teardown for each test
  def setup
    DatabaseCleaner.start
  end
  
  def teardown
    DatabaseCleaner.clean
  end
end
```

## 2. Test Structure Best Practices

### 2.1 Test Class Structure
```ruby
class UserTest < ActiveSupport::TestCase
  # Test groups are defined with comments or nested classes
  
  # Validations
  test "requires an email" do
    user = User.new(email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end
  
  test "requires a unique email" do
    Fabricate(:user, email: "test@example.com")
    user = User.new(email: "test@example.com")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end
  
  # You can create nested classes for better organization
  class AssociationsTest < UserTest
    test "has many posts" do 
      user = Fabricate(:user)
      post = Fabricate(:post, user: user)
      assert_includes user.posts, post
    end
  end
end
```

### 2.2 Test Filtering and Selection
```ruby
# Run specific tests with name patterns
# Command: ruby -Itest test/models/user_test.rb -n /validations/

# Skip tests conditionally
test "performs slow operation" do
  skip "Too slow for regular runs" if ENV["CI"]
  # test code
end

# Focus on specific tests
test "important behavior" do
  # test code
end

# Run with: ruby -Itest test/models/user_test.rb --name=important
```

### 2.3 Setup and Helper Methods
```ruby
class OrderTest < ActiveSupport::TestCase
  # Define setup for each test
  def setup
    @user = Fabricate(:user)
    @product = Fabricate(:product, price: 10.00)
    @item = Fabricate(:order_item, product: @product, quantity: 2)
    @order = Fabricate(:order, user: @user, items: [@item])
  end
  
  # Test methods
  test "calculates the total correctly" do
    assert_equal 20.00, @order.total
  end
  
  # Helper methods
  def create_order_with_items(item_count)
    items = item_count.times.map { Fabricate(:order_item) }
    Fabricate(:order, items: items)
  end
end
```

## 3. Testing API Interactions

### 3.1 Service Testing with VCR
```ruby
class ApiServiceTest < ActiveSupport::TestCase
  test "fetches data successfully" do
    use_vcr_cassette("api_service/fetch_data_success") do
      service = ApiService.new
      response = service.fetch_data
      assert_includes response, expected_data
    end
  end

  test "handles unavailable service" do
    stub_request(:get, /api\.example\.com/).
      to_return(status: 503)
      
    service = ApiService.new
    assert_raises(ApiService::ServiceUnavailable) do
      service.fetch_data
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
# Use within test methods
def test_fetches_data_with_new_recording
  VCR.use_cassette("api_service/fetch_data", record: :new_episodes) do
    # test code
  end
end

def test_fetches_data_with_all_recording
  VCR.use_cassette("api_service/fetch_data", record: :all) do
    # test code
  end
end

def test_fetches_data_with_no_recording
  VCR.use_cassette("api_service/fetch_data", record: :none) do
    # test code
  end
end
```

## 4. Testing Service Objects or Operations

### 4.0 Testing Service Objects
```ruby
class ApiServiceTest < ActiveSupport::TestCase
  setup do
    @client = Minitest::Mock.new
    @service = ApiService.new(@client)
  end
  
  test "returns parsed JSON with successful response" do
    response = Struct.new(:status, :body).new(200, '{"key":"value"}')
    @client.expect(:get, response, ["/endpoint"])
    
    result = @service.fetch_data
    assert_equal({"key" => "value"}, result)
    @client.verify
  end
  
  test "raises ServiceUnavailable error when service is down" do
    response = Struct.new(:status, :body).new(503, '')
    @client.expect(:get, response, ["/endpoint"])
    
    assert_raises(ApiService::ServiceUnavailable) do
      @service.fetch_data
    end
    @client.verify
  end
end
```

## 5. Error Handling in Tests

### 5.1 Exception Testing
```ruby
test "raises an appropriate error" do
  assert_raises(ApiService::Error) do
    service.fetch_data
  end
end

test "raises a specific error with message" do
  error = assert_raises(ApiService::ResourceNotFound) do
    service.fetch_data
  end
  assert_equal "Resource not found", error.message
end

test "doesn't raise an error" do
  assert_silent do
    service.fetch_data
  end
end
```

### 5.2 Testing Recovery Procedures
```ruby
test "uses fallback source when primary source fails" do
  service = ApiService.new
  def service.fetch_from_primary
    raise ApiService::Error
  end
  
  mock = Minitest::Mock.new
  mock.expect :call, {"data" => "fallback"}, []
  service.define_singleton_method(:fetch_from_fallback) do
    mock.call
  end
  
  service.fetch_with_fallback
  mock.verify
end
```

## 6. Continuous Integration Testing

### 6.1 CI Configuration Guidelines
```yaml
# .gitlab-ci.yml or .github/workflows/minitest.yml
test:
  script:
    # Set up test environment
    - export RAILS_ENV=test
    - bundle install --jobs $(nproc) --retry 3
    # Run tests
    - bundle exec rails test
    # Optional: Generate coverage report 
    - bundle exec rails test:coverage
  artifacts:
    paths:
      - coverage/
      - test/reports/
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
1. Use `parallelize(workers: :number_of_processors)` wisely
2. Avoid dependencies between tests
3. Reset database and global state between tests
4. Use unique test data to prevent interference

## 7. Debugging Test Failures

### 7.1 Techniques
1. Use `--name` to run specific tests
2. Run with `-v` for verbose output
3. Add `puts` statements for debugging
4. Use `Minitest::Debugger` to pause execution

### 7.2 Common Issues
1. Time-dependent failures (freeze time with `travel_to`)
2. Order-dependent failures (improve isolation)
3. VCR cassette incompatibilities (re-record)
4. Database state leakage (ensure proper cleanup)

## 8. Minitest Extensions and Plugins

### 8.1 Recommended Plugins
```ruby
# Gemfile
group :test do
  gem "minitest-focus"      # Run specific tests with focus
  gem "minitest-hooks"      # Add before/after hooks
  gem "minitest-around"     # Add around hooks
  gem "minitest-stub_any_instance" # Add stub_any_instance method
  gem "minitest-given"      # Add RSpec-like Given/When/Then syntax
end
```

### 8.2 Custom Assertions
```ruby
# test/support/custom_assertions.rb
module CustomAssertions
  def assert_json_response(json)
    assert_equal "application/json", @response.content_type
    assert_kind_of Hash, json
  end
  
  def assert_successful_response
    assert_response :success
    assert_json_response JSON.parse(@response.body)
  end
end

# Include in your test classes
class ApiControllerTest < ActionDispatch::IntegrationTest
  include CustomAssertions
  
  test "gets index" do
    get api_users_path
    assert_successful_response
  end
end