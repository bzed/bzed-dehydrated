require 'spec_helper'

describe 'dehydrated' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      next if os_facts[:kernel] == 'windows' && !WINDOWS

      before(:each) do
        Puppet::Parser::Functions.newfunction(:puppetdb_query, type: :rvalue) { [] } # W: Use the new Ruby 1.9 hash syntax.
      end
      let(:facts) { os_facts }
      let(:params) do
        {
          'dehydrated_host' => os_facts[:fqdn],
        }
      end

      it { is_expected.to compile }
    end
  end
end
