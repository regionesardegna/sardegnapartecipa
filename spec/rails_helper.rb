# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
ENV['HTTP_PORT'] ||= '80'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'factory_bot_rails'
require 'wisper/rspec/matchers'

# Load Decidim core & component factories
require 'decidim/core/test/factories'
%w(
  accountability
  assemblies
  blogs
  budgets
  comments
  debates
  forms
  meetings
  pages
  participatory_processes
  proposals
  sortitions
  surveys
  system
  templates
  verifications
).each do |mod|
  begin
    require "decidim/#{mod}/test/factories"
  rescue LoadError
  end
end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories.
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.use_transactional_fixtures = true

  config.include FactoryBot::Syntax::Methods
  config.include Wisper::RSpec::BroadcastMatcher
  config.include ActiveJob::TestHelper
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.before(:each) do
    ActiveJob::Base.queue_adapter = :test
    Warden.test_mode!
  end

  config.after(:each) do
    Warden.test_reset!
  end
end
