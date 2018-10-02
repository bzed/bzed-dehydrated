require 'spec_helper'

if Puppet::Util::Package.versioncmp(Puppet.version, '4.5.0') >= 0
  describe 'Dehydrated::Algorithm' do
    describe 'accept letsencrypt algorithms type' do
      [
        'rsa',
        'prime256v1',
        'secp384r1',
      ].each do |value|
        describe value.inspect do
          it { is_expected.to allow_value(value) }
        end
      end
    end

    describe 'rejects other values' do
      [
        'http-01',
        'dns-01',
        'foo-01',
        'bar-02',
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
