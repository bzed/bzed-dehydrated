require 'rspec-puppet'
require 'rspec-puppet-facts'
include RspecPuppetFacts

require 'rspec/support/ruby_features'
require 'spec_helper'

RSpec.configure do |c|
  c.before :each do
    # don't fail spec tests, re-implement assert_private here.
    Puppet::Parser::Functions.newfunction(:assert_private, type: :rvalue) do |args|
    end
    # no puppetdb available during spec tests.
    # TODO: return more than just an empty array
    Puppet::Parser::Functions.newfunction(:puppetdb_query, type: :rvalue) do |args|
      query = args[0]
      if query.empty?
        nil
      else
        []
      end
    end
  end
end

WINDOWS = defined?(RSpec::Support) ? RSpec::Support::OS.windows? : !File::ALT_SEPARATOR.nil?

add_custom_fact :puppet_vardir, ->(os, _facts) do
  if %r{windows.*}.match?(os)
    'C:/ProgramData/PuppetLabs/puppet/var'
  else
    '/var/lib/puppet'
  end
end
add_custom_fact :identity, ->(os, _facts) do
  privileged = true
  if %r{windows.*}.match?(os)
    user = 'MYDOMAIN\\Administrator'
    group = nil
  else
    user = 'root'
    group = 'root'
  end
  {
    'user' => user,
    'group' => group,
    'privileged' => privileged,
  }
end
