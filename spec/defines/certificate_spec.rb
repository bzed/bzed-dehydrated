require 'spec_helper'

describe 'dehydrated::certificate' do
  let(:title) { 'dehydrated.certificate.example.com' }
  let(:params) do
    {}
  end

  on_supported_os.each do |os, os_facts|
    next if os_facts[:kernel] == 'windows' && !WINDOWS

    let :pre_condition do
      if %r{windows.*}.match?(os)
        'class { "dehydrated" : dehydrated_host => "some.other.host.example.com" }'
      else
        'class { "dehydrated" : dehydrated_host => $facts["fqdn"] }'
      end
    end

    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
