# frozen_string_literal: true

require 'spec_helper'

describe 'dehydrated::setup::requests' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      before(:each) do
        Puppet::Parser::Functions.newfunction(:puppetdb_query, type: :rvalue) { [] } # W: Use the new Ruby 1.9 hash syntax.
      end

      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }
    end
  end
end
