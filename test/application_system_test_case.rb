require "test_helper"
require "capybara/minitest"
require "selenium/webdriver"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  include Warden::Test::Helpers

  def sign_in(user)
    login_as(user, scope: :user)
  end

  def teardown
    Warden.test_reset!
    super
  end
end
