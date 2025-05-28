# frozen_string_literal: true

require 'spec_helper'

if Puppet::Util::Package.versioncmp(Puppet.version, '4.5.0') >= 0
  describe 'Dehydrated::WildcardDN' do
    describe 'accepts wildcarddn' do
      [
        '*.example.com',
        '*.bzed.at',
      ].each do |value|
        describe value.inspect do
          it { is_expected.to allow_value(value) }
        end
      end
    end

    describe 'rejects other values' do
      [
        true,
        'true',
        false,
        'false',
        'iAmAString',
        '1test',
        '1 test',
        'test 1',
        'test 1 test',
        {},
        { 'key' => 'value' },
        { 1 => 2 },
        '',
        :undef,
        'x',
        '*',
        'foo.bar.com',
        ['*', '.foo.bar'],
        'foo.*.bar.com',
      ].each do |value|
        describe value.inspect do
          it { is_expected.not_to allow_value(value) }
        end
      end
    end
  end
end
