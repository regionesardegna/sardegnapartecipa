# initializers/sql_logging.rb
ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)