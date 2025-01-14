# frozen_string_literal: true

require 'spec_helper'

describe 'dehydrated::certificate::dh' do
  let(:pre_condition) do
    <<~PUPPET
      function puppetdb_query(String[1] $data) {
        return [
        ]
      }
      class { "dehydrated" : dehydrated_host => $facts["fqdn"] }
    PUPPET
  end
  let(:title) { 'dh.certificate.dehydrated' }
  let(:params) do
    { 'dn' => 'dh.certificate.dehydrated', 'dh_param_size' => 1024 }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      next if os_facts[:kernel] == 'windows'

      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
