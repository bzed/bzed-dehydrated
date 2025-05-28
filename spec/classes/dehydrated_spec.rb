# frozen_string_literal: true

require 'spec_helper'

describe 'dehydrated' do
  let(:pre_condition) do
    <<~PUPPET
      function puppetdb_query(String[1] $data) {
        return [
        ]
      }
    PUPPET
  end

  on_supported_os.each do |os, os_facts|
    let(:facts) { os_facts }
    let(:params) do
      {
        'dehydrated_host' => os_facts[:networking][:fqdn],
      }
    end

    context "on #{os}" do
      next if os_facts[:kernel] == 'windows'

      it { is_expected.to compile }
    end
  end
end
