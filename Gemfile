# Managed by modulesync - DO NOT EDIT
# https://voxpupuli.org/docs/updating-files-managed-with-modulesync/

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

group :test do
  gem 'voxpupuli-test', '~> 9.0',   :require => false
  gem 'coveralls',                  :require => false
  gem 'simplecov-console',          :require => false
  gem 'puppet_metadata', '~> 4.0',  :require => false
end

group :development do
  gem 'guard-rake',                             :require => false
  gem 'overcommit', '>= 0.39.1',                :require => false
  gem 'github_changelog_generator',             :require => false, :git => 'https://github.com/skywinder/github-changelog-generator'
  gem 'rspec-puppet',                           :require => false
  gem 'puppet-strings',                         :require => false
  gem 'rgen',                                   :require => false
  gem 'hiera-eyaml',                            :require => false
  gem 'puppet-lint-resource_reference_syntax',  :require => false
  gem 'puppet-lint-trailing_comma-check',       :require => false
  gem 'puppet-lint-variable_contains_upcase',   :require => false
end

group :system_tests do
  gem 'voxpupuli-acceptance', '~> 3.0',  :require => false
end

group :release do
  gem 'voxpupuli-release', '~> 3.0',  :require => false
end

gem 'rake', :require => false
gem 'facter', ENV['FACTER_GEM_VERSION'], :require => false, :groups => [:test]

puppetversion = ENV['PUPPET_GEM_VERSION'] || [">= 7.24", "< 9"]
gem 'puppet', puppetversion, :require => false, :groups => [:test]

# vim: syntax=ruby
