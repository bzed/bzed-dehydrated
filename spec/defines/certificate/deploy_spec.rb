require 'spec_helper'

describe 'dehydrated::certificate::deploy' do
  let(:title) { 'namevar' }
  let(:params) do
    { 'dn' => 'test.example.com' }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      next if os_facts[:kernel] == 'windows' && !WINDOWS

      let(:facts) { os_facts }

      let :pre_condition do
        [
          'class { "dehydrated" : dehydrated_host => "test.example.com" }',
          'dehydrated_key{ "/etc/pki/dehydrated/private/test.example.com.key": }',
          'dehydrated_key{ "/etc/dehydrated/private/test.example.com.key": }',
          'file{"/etc/dehydrated/certs/test.example.com.crt": }',
          'file{"/etc/dehydrated/certs/test.example.com_ca.pem": }',
          'file{"/etc/dehydrated/private/test.example.com.key": }',
          'file{"/etc/pki/dehydrated/certs/test.example.com.crt": }',
          'file{"/etc/pki/dehydrated/certs/test.example.com_ca.pem": }',
          'file{"/etc/pki/dehydrated/private/test.example.com.key": }',
        ].join("\n")
      end

      it { is_expected.to compile }
    end
  end
end
