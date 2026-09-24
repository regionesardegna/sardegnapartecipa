# spec/rails_helper.rb
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'capybara/rspec'
require 'rack_session_access/capybara'

# Carichiamo le factory ufficiali di Decidim
require 'decidim/core/test/factories'

# 1. Registrazione del driver sicuro per Linux
Capybara.register_driver :headless_chrome_linux do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  # Questa è la sintassi che fa felice sia Capybara 3.40 che Selenium 4.1
  Capybara::Selenium::Driver.new(app, browser: :chrome, capabilities: [options])
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  # 2. Istruiamo i test di sistema a usare il driver appena registrato
  config.before(:each, type: :system) do
    driven_by :headless_chrome_linux
  end
end