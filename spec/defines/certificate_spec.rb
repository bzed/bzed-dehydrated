require 'spec_helper'

describe 'dehydrated::certificate' do
    let(:title) { 'test.exmaple.com' }
    let(:params) do
        {}
    end

    let :pre_condition do
        'class { "dehydrated" : }'
    end


    on_supported_os.each do |os, os_facts|
        context "on #{os}" do
            let(:facts) { os_facts }

            it { is_expected.to compile }
        end
    end
end
