# frozen_string_literal: true

require 'spec_helper'

describe 'dehydrated::setup::requests' do
  on_supported_os.each do |os, os_facts|
    next if os_facts[:kernel] == 'windows' && !WINDOWS

    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }
    end
  end
end
