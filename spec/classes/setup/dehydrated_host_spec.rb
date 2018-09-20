require 'spec_helper'

describe 'dehydrated::setup::dehydrated_host' do
  let :pre_condition do
    'class { "dehydrated" : }'
  end

  on_supported_os.each do |os, os_facts|

    next if os_facts[:kernel] == 'windows' and !WINDOWS

    context "on #{os}" do
      let(:facts) { os_facts }
    end
  end
end
