require 'spec_helper'

if Puppet::Util::Package.versioncmp(Puppet.version, '4.5.0') >= 0
  describe 'Dehydrated::Hook' do
    describe 'accepts valid hook filenames' do
      [
        'foo',
        'foo.sh',
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
        '/foo/bar',
        '\\foo\\bar',
        {},
        { 'key' => 'value' },
        { 1 => 2 },
        :undef,
        ['*', '.foo.bar'],
        [nil],
        [nil, nil],
        { 'foo' => 'bar' },
        {},
        '',
      ].each do |value|
        describe value.inspect do
          it { is_expected.not_to allow_value(value) }
        end
      end
    end
  end
end
