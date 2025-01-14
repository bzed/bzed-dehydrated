# frozen_string_literal: true

require 'spec_helper'

# buggy rubocop
# rubocop:disable RSpec/EmptyExampleGroup
describe 'dehydrated::setup::dehydrated_host' do
  on_supported_os.each do |os, os_facts|
    next if os_facts[:kernel] == 'windows'

    let :pre_condition do
      if %r{windows.*}.match?(os)
        'class { "dehydrated" : dehydrated_host => "some.other.host.example.com" }'
      else
        'class { "dehydrated" : dehydrated_host => $facts["networking"]["fqdn"] }'
      end
    end

    context "on #{os}" do
      let(:facts) { os_facts }
    end
  end
end
