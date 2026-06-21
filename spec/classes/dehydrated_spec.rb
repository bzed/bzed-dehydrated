# frozen_string_literal: true

require 'spec_helper'

describe 'dehydrated' do
  let(:pre_condition) do
    <<~PUPPET
      function puppetdb_query(String[1] $data) {
        return [
        ]
      }
    PUPPET
  end

  on_supported_os.each do |os, os_facts|
    next if os_facts[:kernel] == 'windows'

    context "on #{os}" do
      let(:facts) { os_facts }
      let(:trusted_facts) do
        {
          'certname' => 'dehydrated.example.com'
        }
      end
      let(:params) do
        {
          'dehydrated_host' => 'dehydrated.example.com',
        }
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('dehydrated::setup') }

      context 'with default parameters' do
        it 'creates correct base directory for Debian' do
          expect(catalogue).to contain_file('/etc/dehydrated').with_ensure('directory') if os_facts[:os]['family'] == 'Debian'
        end

        it 'creates correct base directory for non-Debian' do
          expect(catalogue).to contain_file('/etc/pki/dehydrated').with_ensure('directory') unless os_facts[:os]['family'] == 'Debian'
        end
      end

      context 'with custom base_dir' do
        let(:params) do
          super().merge({
                          'base_dir' => '/custom/cert/path'
                        })
        end

        it { is_expected.to contain_file('/custom/cert/path').with_ensure('directory') }
        it { is_expected.to contain_file('/custom/cert/path/certs').with_ensure('directory') }
        it { is_expected.to contain_file('/custom/cert/path/csr').with_ensure('directory') }
        it { is_expected.to contain_file('/custom/cert/path/private').with_ensure('directory') }
      end

      context 'with certificates parameter' do
        let(:params) do
          super().merge({
                          'certificates' => ['test.example.com', ['www.example.com', ['www.example.com', 'example.com']]]
                        })
        end

        it { is_expected.to contain_dehydrated__certificate('test.example.com') }
        it { is_expected.to contain_dehydrated__certificate('www.example.com') }
      end

      context 'with custom user and group' do
        let(:params) do
          super().merge({
                          'user' => 'customuser',
                          'group' => 'customgroup'
                        })
        end

        it { is_expected.to contain_file('/etc/dehydrated').with_owner('customuser') } if os_facts[:os]['family'] == 'Debian'
        it { is_expected.to contain_file('/etc/pki/dehydrated').with_owner('customuser') } unless os_facts[:os]['family'] == 'Debian'
      end

      context 'when acting as dehydrated_host' do
        let(:params) do
          super().merge({
                          'dehydrated_host' => os_facts[:networking]['fqdn']
                        })
        end
        let(:node) { os_facts[:networking]['fqdn'] }

        it { is_expected.to contain_class('dehydrated::setup::dehydrated_host') }
        it { is_expected.to contain_class('dehydrated::setup::requests') }
      end

      context 'with invalid parameters' do
        let(:params) do
          {
            'base_dir' => 'invalid/path'
          }
        end

        it { is_expected.to compile.and_raise_error(%r{expects a Stdlib::Absolutepath}) }
      end
    end
  end

  context 'on Windows' do
    let(:facts) do
      {
        kernel: 'windows',
        os: {
          name: 'windows',
          family: 'windows',
          release: { full: '2019' }
        },
        identity: { 'user' => 'SYSTEM' },
        puppet_vardir: 'C:/ProgramData/PuppetLabs/puppet/var',
        networking: { fqdn: 'windows.example.com' }
      }
    end

    let(:params) do
      {
        'dehydrated_host' => 'windows.example.com',
        'user' => 'SYSTEM',
        'group' => 'Users'
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('C:/LE_certs').with_ensure('directory') }
  end
end
