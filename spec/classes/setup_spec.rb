require 'spec_helper'

describe 'dehydrated::setup' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :pre_condition do
        if os =~ %r{windows.*}
          'class { "dehydrated" : dehydrated_host => "some.other.host.example.com" }'
        else
          'class { "dehydrated" : dehydrated_host => $facts["fqdn"] }'
        end
      end
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
