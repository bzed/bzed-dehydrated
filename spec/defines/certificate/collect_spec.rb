require 'spec_helper'

describe 'dehydrated::certificate::collect' do
  let(:title) { 'namevar' }
  let(:params) do
    {
      'request_dn' => 'test.example.com',
      'request_fqdn' => 'test.example.com',
      'request_base_dir' => '/opt/dehydrated/requests',
      'request_base_filename' => 'test.example.com'
    }
  end

  let :pre_condition do
    'class { "dehydrated" : }'
  end

  on_supported_os.each do |os, os_facts|
    next if os_facts[:kernel] == 'windows'

    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
