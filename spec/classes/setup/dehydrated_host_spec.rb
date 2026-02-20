# frozen_string_literal: true

require 'spec_helper'

describe 'dehydrated::setup::dehydrated_host' do
  let(:pre_condition) do
    <<~PUPPET
      function puppetdb_query(String[1] $data) {
        return [
        ]
      }
      function assert_private() {
      }
      class { 'dehydrated' : dehydrated_host => $facts['networking']['fqdn'] }
    PUPPET
  end

  on_supported_os.each do |os, os_facts|
    next if os_facts[:kernel] == 'windows'

    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('dehydrated::setup') }

      it { is_expected.to contain_file('/opt/dehydrated').with_ensure('directory') }
      it { is_expected.to contain_file('/opt/dehydrated/requests').with_ensure('directory') }
      it { is_expected.to contain_file('/opt/dehydrated/hooks').with_ensure('directory') }

      context 'with custom git configuration' do
        let(:pre_condition) do
          <<~PUPPET
            function puppetdb_query(String[1] $data) {
              return [
              ]
            }
            function assert_private() {
            }
            class { 'dehydrated' : 
              dehydrated_host => $facts['networking']['fqdn'],
              dehydrated_git_url => 'https://internal.git/dehydrated',
              dehydrated_git_tag => 'v1.0.0'
            }
          PUPPET
        end

        it { is_expected.to contain_vcsrepo('/opt/dehydrated/dehydrated').with_source('https://internal.git/dehydrated') }
        it { is_expected.to contain_vcsrepo('/opt/dehydrated/dehydrated').with_revision('v1.0.0') }
      end

      context 'with custom base directory' do
        let(:pre_condition) do
          <<~PUPPET
            function puppetdb_query(String[1] $data) {
              return [
              ]
            }
            function assert_private() {
            }
            class { 'dehydrated' : 
              dehydrated_host => $facts['networking']['fqdn'],
              dehydrated_base_dir => '/custom/dehydrated'
            }
          PUPPET
        end

        it { is_expected.to contain_file('/custom/dehydrated').with_ensure('directory') }
        it { is_expected.to contain_file('/custom/dehydrated/requests').with_ensure('directory') }
      end

      context 'with package management' do
        it { is_expected.to contain_package('jq') }
      end

      context 'with custom user and group' do
        let(:pre_condition) do
          <<~PUPPET
            function puppetdb_query(String[1] $data) {
              return [
              ]
            }
            function assert_private() {
            }
            class { 'dehydrated' : 
              dehydrated_host => $facts['networking']['fqdn'],
              dehydrated_user => 'customuser',
              dehydrated_group => 'customgroup'
            }
          PUPPET
        end

        it { is_expected.to contain_file('/opt/dehydrated').with_owner('customuser') }
        it { is_expected.to contain_file('/opt/dehydrated/requests').with_owner('customuser') }
      end
    end
  end
end
