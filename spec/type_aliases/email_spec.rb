# frozen_string_literal: true

require 'spec_helper'

if Puppet::Util::Package.versioncmp(Puppet.version, '4.5.0') >= 0
  describe 'Dehydrated::Email' do
    describe 'accepts valid email addresses' do
      [
        'foo@bar.com',
        'foo+fuzz@bar.com',
        'firstname.lastname@domain.com',
        'email@subdomain.domain.com',
        '"email"@domain.com',
        '1234567890@domain.com',
        'Firstname-Lastname@domain.com',
        '_______@domain.com',
      ].each do |value|
        describe value.inspect do
          it { is_expected.to allow_value(value) }
        end
      end
    end

    describe 'rejects other values' do
      [
        'foo',
        '#@%^%#$@#$@#.com',
        '@domain',
        'Joe Smith <email@domain.com>',
        'email.domain.com',
        'email@domain@domain.com',
        '.email@domain.com',
        'あいうえお@domain.com',
        'email@domain.com (Joe Smith)',
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
