require 'spec_helper'

describe 'dehydrated::certificate::csr' do
  let(:title) { 'csr.certificate.dehydrated' }
  let(:params) do
    { 'dn' => 'csr.certificate.dehydrated', 'subject_alternative_names' => ['*.csr.certificate.dehydrated'] }
  end

  let :pre_condition do
    'class { "dehydrated" : }'
  end

  on_supported_os.each do |os, os_facts|
    next if os_facts[:kernel] == 'windows' && !WINDOWS

    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
