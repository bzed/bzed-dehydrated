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
  let(:title) { 'test.example.com' }
  let(:params) do
    {
      'dn' => 'test.example.com',
      'subject_alternative_names' => ['www.test.example.com'],
    }
  end

  on_supported_os.each do |os, os_facts|
    next if os_facts[:kernel] == 'windows'

    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_dehydrated_key('test.example.com.key') }
      it { is_expected.to contain_dehydrated_fingerprint('test.example.com.key.fingerprint') }
      it { is_expected.to contain_dehydrated_csr('test.example.com.csr') }

      context 'with key_password' do
        let(:params) do
          super().merge({
            'key_password' => 'secret'
          })
        end

        it { is_expected.to contain_dehydrated_key('test.example.com.key').with_password('secret') }
        it { is_expected.to contain_dehydrated_fingerprint('test.example.com.key.fingerprint').with_password('secret') }
        it { is_expected.to contain_dehydrated_csr('test.example.com.csr').with_password('secret') }
      end

      context 'with different algorithm' do
        let(:params) do
          super().merge({
            'algorithm' => 'prime256v1'
          })
        end

        it { is_expected.to contain_dehydrated_key('test.example.com.key').with_algorithm('prime256v1') }
        it { is_expected.to contain_dehydrated_csr('test.example.com.csr').with_algorithm('prime256v1') }
      end

      context 'with custom filenames' do
        let(:params) do
          super().merge({
            'base_filename' => 'custom_name',
            'csr_filename' => 'custom.csr',
            'key_filename' => 'custom.key'
          })
        end

        it { is_expected.to contain_dehydrated_key('custom.key') }
        it { is_expected.to contain_dehydrated_csr('custom.csr') }
      end

      context 'with ensure => absent' do
        let(:params) do
          super().merge({
            'ensure' => 'absent'
          })
        end

        it { is_expected.to contain_dehydrated_key('test.example.com.key').with_ensure('absent') }
        it { is_expected.to contain_dehydrated_csr('test.example.com.csr').with_ensure('absent') }
        it { is_expected.to contain_file('test.example.com.key').with_ensure('absent') }
        it { is_expected.to contain_file('test.example.com.csr').with_ensure('absent') }
      end

      context 'with file permissions' do
        it { is_expected.to contain_file('test.example.com.key').with_mode('0640') }
        it { is_expected.to contain_file('test.example.com.csr').with_mode('0644') }
      end

      context 'with custom user and group' do
        let(:pre_condition) do
          <<~PUPPET
            function puppetdb_query(String[1] $data) {
              return [
              ]
            }
            class { "dehydrated" : 
              dehydrated_host => $facts["fqdn"],
              user => 'customuser',
              group => 'customgroup'
            }
          PUPPET
        end

        it { is_expected.to contain_file('test.example.com.key').with_owner('customuser') }
        it { is_expected.to contain_file('test.example.com.csr').with_owner('customuser') }
      end
    end
  end
end
