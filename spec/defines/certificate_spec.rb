# frozen_string_literal: true

require 'spec_helper'

describe 'dehydrated::certificate' do
  let(:title) { 'test.example.com' }
  let(:node) { 'dehydrated.example.com' }
  let(:params) do
    {}
  end
  let(:trusted_facts) do
    {
      'certname' => 'dehydrated.example.com'
    }
  end
  let(:pre_condition) do
    <<~PUPPET
      function assert_private() {}
      function puppetdb_query(String[1] $data) {
        if 'Dehydrated::Certificate::Transfer' in $data {
          return [
            { 'parameters.file_type' => 'ca', 'parameters.file_content' => 'ca_content' },
            { 'parameters.file_type' => 'crt', 'parameters.file_content' => 'crt_content' }
          ]
        }
        return []
      }
      class { "dehydrated" : dehydrated_host => 'dehydrated.example.com' }
    PUPPET
  end

  on_supported_os.each do |os, os_facts|
    next if os_facts[:kernel] == 'windows'

    context "on #{os}" do
      let(:facts) { os_facts }
      let(:base_dir) { os_facts[:os]['family'] == 'Debian' ? '/etc/dehydrated' : '/etc/pki/dehydrated' }

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_dehydrated__certificate__csr('test.example.com') }

      context 'with subject_alternative_names' do
        let(:params) do
          {
            'subject_alternative_names' => ['www.example.com', 'example.com']
          }
        end

        it { is_expected.to contain_dehydrated__certificate__csr('test.example.com') }
        it { is_expected.to contain_concat__fragment('dehydrated.example.com-test.example.com') }
      end

      context 'with custom algorithm' do
        let(:params) do
          {
            'algorithm' => 'prime256v1'
          }
        end

        it { is_expected.to contain_dehydrated_key("#{base_dir}/private/test.example.com.key").with_algorithm('prime256v1') }
      end

      context 'with custom base_filename' do
        let(:params) do
          {
            'base_filename' => 'custom_filename'
          }
        end
        let(:facts) do
          os_facts.merge({
                           dehydrated_domains: {
                             'test.example.com' => {
                               'base_filename' => 'custom_filename',
                               'challengetype' => 'dns-01',
                               'dehydrated_host' => 'dehydrated.example.com',
                               'dh_param_size' => 4096,
                               'subject_alternative_names' => []
                             }
                           }
                         })
        end

        it { is_expected.to contain_dehydrated__certificate__csr('custom_filename') }
      end

      context 'with ensure => absent' do
        let(:params) do
          {
            'ensure' => 'absent'
          }
        end

        it { is_expected.to contain_dehydrated__certificate__deploy('test.example.com').with_ensure('absent') }
      end

      context 'with key_password' do
        let(:params) do
          {
            'key_password' => 'secret_password'
          }
        end

        it { is_expected.to contain_dehydrated__certificate__csr('test.example.com') }
        it { is_expected.to contain_dehydrated__certificate__deploy('test.example.com').with_key_password('secret_password') }
      end

      context 'with different challenge type' do
        let(:params) do
          {
            'challengetype' => 'http-01'
          }
        end

        it { is_expected.to contain_concat__fragment('dehydrated.example.com-test.example.com') }
      end

      context 'with invalid dn format' do
        let(:title) { 'invalid dn!' }

        it { is_expected.to compile.and_raise_error(%r{expects a Dehydrated::DN}) }
      end
    end
  end
end
