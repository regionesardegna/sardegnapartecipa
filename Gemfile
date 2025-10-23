# frozen_string_literal: true

source 'http://rubygems.org'

ruby RUBY_VERSION

DECIDIM_VERSION = 'release/0.28-stable'

gem 'bootsnap', '~> 1.3'
gem 'daemons'
gem 'decidim', git: 'http://github.com/decidim/decidim', branch: DECIDIM_VERSION
gem 'decidim-decidim_awesome'
gem 'decidim-privacy', git: 'https://github.com/dipartimentofunzionepubblica/decidim-module-privacy', branch: 'release/0.28'
gem 'decidim-spid-cie', git: 'https://gitlab.com/glcorso/decidim-module-spid-cie', branch: 'release/0.28'
gem 'decidim-templates', git: 'https://github.com/decidim/decidim', tag: DECIDIM_VERSION
gem 'decidim-term_customizer', git: 'https://github.com/mainio/decidim-module-term_customizer'
gem 'decidim-cache_cleaner'
gem 'decidim-extra_user_fields', git: 'https://github.com/PopulateTools/decidim-module-extra_user_fields.git', branch: 'release/0.28-stable'
gem 'deface'
gem 'delayed_job_active_record'
gem 'figaro'
gem 'foundation_rails_helper', git: 'http://github.com/sgruhier/foundation_rails_helper.git'
gem 'lograge'
gem 'pg'
gem "puma", ">= 6.3.1"
gem 'wicked_pdf', "~> 2.1"
gem 'wkhtmltopdf-binary'


group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev"
  gem "brakeman", "~> 5.4"
  gem "net-imap", "~> 0.2.3"
  gem "net-pop", "~> 0.1.1"
  gem "net-smtp", "~> 0.3.1"
end

group :development do
  gem "letter_opener_web", "~> 2.0"
  gem "listen", "~> 3.1"
  gem "web-console", "~> 4.2"
  #gem 'rubocop-faker'
  #gem 'spring' 
  #gem 'spring-watcher-listen'
  #gem 'active_record_query_trace'
  #gem 'sql_tracker'
  #gem 'awesome_print'
  #gem 'pry'
  #gem 'pry-byebug' # Integrates pry with byebug
  #gem 'pry-doc' # Provide MRI Core documentation
  #gem 'pry-rails'
end
