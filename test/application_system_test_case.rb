require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Use Chrome's modern headless mode. The legacy `:headless_chrome` mode
  # (--headless) has DOM/CDP inconsistencies on recent Chrome that intermittently
  # raise "Node with given id does not belong to the document" during Capybara
  # visibility checks. The extra flags stabilize Chrome in CI containers.
  driven_by :selenium, using: :chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
  end
end
