# frozen_string_literal: true

require 'spec_helper'

describe 'dehydrated::setup' do
  let(:pre_condition) do
    <<~PUPPET
      function puppetdb_query(String[1] $data) {
        return [
        ]
      }
      class { 'dehydrated' : dehydrated_host => $facts['networking']['fqdn'] }
    PUPPET
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      next if os_facts[:kernel] == 'windows'

      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
