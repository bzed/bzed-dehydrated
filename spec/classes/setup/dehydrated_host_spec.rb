require 'spec_helper'

# buggy rubocop
# rubocop:disable RSpec/EmptyExampleGroup
describe 'dehydrated::setup::dehydrated_host' do
  on_supported_os.each do |os, os_facts|
    next if os_facts[:kernel] == 'windows' && !WINDOWS

    let :pre_condition do
      if os =~ %r{windows.*}
        'class { "dehydrated" : dehydrated_host => "some.other.host.example.com" }'
      else
        'class { "dehydrated" : dehydrated_host => $facts["fqdn"] }'
      end
    end

    context "on #{os}" do
      let(:facts) { os_facts }
    end
  end
end
