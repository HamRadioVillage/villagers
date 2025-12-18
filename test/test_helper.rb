ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Force routes to be loaded so Devise mappings are available
Rails.application.reload_routes!

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # Disabled (threshold: 1000) due to Devise mapping race conditions with parallel processes
    # TODO: Re-enable when Devise fixes parallel test support or we have 1000+ tests
    parallelize(workers: :number_of_processors, threshold: 1000)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Include Devise test helpers
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Auto-confirm users in tests since email confirmation is enabled
  def create_confirmed_user(attrs = {})
    user = User.new({
      email: "test#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    }.merge(attrs))
    user.skip_confirmation!
    user.save!
    user
  end
end

class ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers
end

# Auto-confirm all users created in test environment
User.class_eval do
  after_initialize do
    self.confirmed_at ||= Time.current if new_record? && Rails.env.test?
  end
end
