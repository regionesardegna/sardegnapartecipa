# frozen_string_literal: true

source 'http://rubygems.org'

ruby RUBY_VERSION

DECIDIM_VERSION = 'v0.27.9'


gem 'bootsnap', '~> 1.4'
gem 'daemons'
gem 'decidim', git: 'http://github.com/decidim/decidim', tag: DECIDIM_VERSION
gem 'decidim-decidim_awesome'
gem 'decidim-privacy', git: 'https://github.com/dipartimentofunzionepubblica/decidim-module-privacy', branch: 'bump_to_0.27'
gem 'decidim-spid-cie', git: 'https://gitlab.com/glcorso/decidim-module-spid-cie', branch: 'release/0.27', ref: 'e813e27fa23812f8233dded78d1a675a0ac84659'
gem 'decidim-templates', git: 'https://github.com/decidim/decidim', tag: DECIDIM_VERSION
gem 'decidim-term_customizer', branch: 'release/0.27-stable', git: 'https://github.com/mainio/decidim-module-term_customizer'
gem 'decidim-survey_results', git: 'https://github.com/maintainer-partecipa/decidim-module-survey_results', branch: 'bump_to_0.27'
gem 'decidim-cache_cleaner'
gem 'decidim-friendly_signup', git: 'https://github.com/OpenSourcePolitics/decidim-module-friendly_signup', branch: 'main'
gem 'decidim-extra_user_fields', git: 'https://github.com/PopulateTools/decidim-module-extra_user_fields.git', branch: 'release/0.27-stable'
gem 'deface'
gem 'delayed_job_active_record'
gem 'figaro'
gem 'foundation_rails_helper', git: 'http://github.com/sgruhier/foundation_rails_helper.git'
gem 'lograge'
gem 'pg'
gem 'puma'
gem 'rake'
gem 'uglifier', '~> 4.1'
gem 'mini_portile2', '~> 2.8.2'
gem 'wicked_pdf', '~> 2.1'
gem 'wkhtmltopdf-binary'
gem 'concurrent-ruby', '1.3.4'

group :development, :test do
  gem 'byebug', '~> 11.0', platform: :mri

  # Use latest simplecov from master until next version of simplecov is
  # released (greather than 0.18.5)
  # See https://github.com/decidim/decidim/issues/6230

  gem 'decidim-dev', git: 'http://github.com/decidim/decidim', tag: DECIDIM_VERSION
  gem 'simplecov', '~> 0.21.0'
  gem 'brakeman', '~> 5.2'
  gem 'parallel_tests', '~> 3.7'
end

group :development do
  gem 'letter_opener_web', '~> 2.0'
  gem 'listen', '~> 3.1'
  gem 'rubocop-faker'
  gem 'spring', '~> 4.0'
  gem 'spring-watcher-listen', '~> 2.1'
  gem 'active_record_query_trace'
  gem 'sql_tracker'
  gem 'awesome_print'
  gem 'xray-rails'
  #gem 'decidim-design'
  #gem 'pry'
  #gem 'pry-byebug' # Integrates pry with byebug
  #gem 'pry-doc' # Provide MRI Core documentation
  #gem 'pry-rails'
end
