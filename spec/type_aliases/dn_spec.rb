require 'spec_helper'

if Puppet::Util::Package.versioncmp(Puppet.version, '4.5.0') >= 0
  describe 'Dehydrated::DN' do
    describe 'accepts dn' do
      [
        '*.example.com',
        '*.bzed.at',
        'example',
        'example.com',
        'www.example.com',
      ].each do |value|
        describe value.inspect do
          it { is_expected.to allow_value(value) }
        end
      end
    end

    describe 'rejects other values' do
      [
        true,
        false,
        '1 test',
        'test 1',
        'test 1 test',
        {},
        { 'key' => 'value' },
        { 1 => 2 },
        '',
        :undef,
        '*',
        ['*', '.foo.bar'],
        'foo.*.bar.com',
                  [nil],
          [nil, nil],
          { 'foo' => 'bar' },
          {},
          '',
          '2001:DB8::1',
          'www www.example.com',
      ].each do |value|
        describe value.inspect do
          it { is_expected.not_to allow_value(value) }
        end
      end
    end
  end
end
