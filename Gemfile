# frozen_string_literal: true

source 'https://rubygems.org'

ruby RUBY_VERSION

DECIDIM_VERSION = 'release/0.29-stable'

gem 'decidim', git: 'https://github.com/decidim/decidim', branch: DECIDIM_VERSION
gem 'decidim-decidim_awesome'
gem 'decidim-privacy', git: 'https://github.com/dipartimentofunzionepubblica/decidim-module-privacy', branch: 'release/0.29'
gem 'decidim-spid-cie', git: 'https://github.com/dipartimentofunzionepubblica/decidim-module-spid-cie', branch: 'release/0.29'
gem 'decidim-templates', git: 'https://github.com/decidim/decidim', branch: DECIDIM_VERSION
#gem 'decidim-term_customizer', git: 'https://github.com/mainio/decidim-module-term_customizer', branch: 'release/0.29-stable'
gem 'decidim-cache_cleaner'
#gem 'decidim-extra_user_fields', git: 'https://github.com/PopulateTools/decidim-module-extra_user_fields.git', branch: 'release/0.29-stable'
gem 'bootsnap'
gem 'puma'
gem 'wicked_pdf', '~> 2.1'
gem 'pg'
gem 'figaro'
gem 'lograge'
gem 'daemons'
gem 'delayed_job_active_record'
#gem 'foundation_rails_helper', git: 'http://github.com/sgruhier/foundation_rails_helper.git'
gem 'deface'
gem 'wkhtmltopdf-binary'
gem 'i18n'
gem 'faker', '~> 3.2'

group :development, :test do
  gem 'rspec-rails', '~> 6.1'
  gem 'byebug', '~> 11.0', platform: :mri
  gem 'decidim-dev', git: 'https://github.com/decidim/decidim'
  gem 'brakeman', '~> 5.4'
  gem 'net-imap', '~> 0.2.3'
  gem 'net-pop', '~> 0.1.1'
  gem 'net-smtp', '~> 0.3.1'
  gem 'i18n-tasks'
  gem 'html_tokenizer'
  gem 'factory_bot_rails'
end

group :development do
  gem 'letter_opener_web', '~> 2.0'
  gem 'listen', '~> 3.1'
  gem 'web-console', '~> 4.2'
end
