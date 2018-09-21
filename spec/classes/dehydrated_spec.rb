require 'spec_helper'

describe 'dehydrated' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      next if os_facts[:kernel] == 'windows' && !WINDOWS

      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
