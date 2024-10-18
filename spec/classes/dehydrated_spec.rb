require 'spec_helper'

describe 'dehydrated' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      next if os_facts[:kernel] == 'windows' && !WINDOWS

      let(:facts) { os_facts }
      let(:params) do
        {
          'dehydrated_host' => os_facts[:fqdn],
        }
      end

      it { is_expected.to compile }
    end
    before :each do
      Puppet::Parser::Functions.newfunction(:puppetdb_query, type: :rvalue) do |_args|
        []
      end
    end
  end
end
