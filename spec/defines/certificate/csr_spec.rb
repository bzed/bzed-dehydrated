# frozen_string_literal: true

require 'spec_helper'

describe 'dehydrated::certificate::csr' do
  let(:pre_condition) do
    <<~PUPPET
      function puppetdb_query(String[1] $data) {
        return [
        ]
      }
      class { "dehydrated" : dehydrated_host => $facts["fqdn"] }
    PUPPET
  end
  let(:title) { 'csr.certificate.dehydrated' }
  let(:params) do
    {
      'dn' => 'csr.certificate.dehydrated',
      'subject_alternative_names' => ['*.csr.certificate.dehydrated'],
      'algorithm' => 'secp384r1',
    }
  end

  on_supported_os.each do |os, os_facts|
    next if os_facts[:kernel] == 'windows'

    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
