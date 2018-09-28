require 'spec_helper'

if Puppet::Util::Package.versioncmp(Puppet.version, '4.5.0') >= 0
  describe 'Dehydrated::CRT' do
    describe 'accepts x509 cert type' do
      [
        # rubocop:disable Metrics/LineLength
        '-----BEGIN CERTIFICATE-----\nMIIEWjCCAkICAQEwDQYJKoZIhvcNAQELBQAwczELMAkGA1UEBhMCQVQxETAPBgNV\nBAgMCFNhbHpidXJnMREwDwYDVQQHDAhTYWx6YnVyZzEYMBYGA1UECgwPYnplZC1k\nZWh5ZHJhdGVkMSQwIgYDVQQDDBtiemVkLWRlaHlkcmF0ZWQuZXhhbXBsZS5jb20w\nHhcNMTgwOTI4MDg1MzU1WhcNMTgxMDAzMDg1MzU1WjBzMQswCQYDVQQGEwJBVDER\nMA8GA1UECAwIU2FsemJ1cmcxETAPBgNVBAcMCFNhbHpidXJnMRgwFgYDVQQKDA9i\nemVkLWRlaHlkcmF0ZWQxJDAiBgNVBAMMG2J6ZWQtZGVoeWRyYXRlZC5leGFtcGxl\nLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMDysktdUS3rn7Ds\nbYkwZ+4rkwTseWioRvKv/qhPsQRPlDmD2QZxEayNgh7a6JIFH8JgsRAdH6SBSFVF\n+3y58FWCEVU7FAkSsDghOLnXs/klKuCxbKjIyEMwpLToHv4SeKdYgvno+T6Ngkih\nI4/+DQdMHtW3q18wUluOyFt0+rG1jVeVHFHqUqihlHafyVQN3DDhBc0X0OSdBRsY\ne/KVXv/A9IKqjQ1z960B36wQAvnvAaZ/Q/kyva5GoB2AqstOMzqEYayHdMDdGQ3s\nJkBaidbJJdV4XLfDxDDIj4eIBtWXgSTs3Q+i7ccCjGRLRJhjPYDotRJ0yyYsJAwM\n9HKv8QECAwEAATANBgkqhkiG9w0BAQsFAAOCAgEAjfxdCfoT+rYfVcGczjY79z3d\nk5d2NVubOf6Ot/PLPOV4S44fYJpJmTz1a3TbFtvZp+qQw2nkKAIr4QeiGjJSGw54\nBTfU43ADFresw9bhyOE3thPbqjZxYF+INxVmEHpRU6S9ZaaQJK49Tj68VIoawdMc\n1r3VFOXSvfN4xcVetaxb7jE40eFlDD4Qm/wPEwSKRwhSS04zToqOq9/PB1iXnmy/\nfAClRmHsYprp7w0zANELV/ZUewErN5D13HLilbGeNIBe2buIyqGianq4zA0bvehi\n6oB0kXBDV/wIkg92/eX8VhdajPVq6HVr8SSmLmpNfSpAPisVV0jfQz13NUZKh9jM\nq2+FxxhHC3qfYAkWhODR75skEJ0BAB/dJpZ8hTaGEslww7RRUGtwUYtMC3dB5GwS\n8fyumziIzLzX5JveWB/qLg4ME7xmbjxWDYqk364BIRI4FOTFrafFKUWBs7wwBTHf\nV/DcIYLaQMTCJK+LI5bjrVRQwZhAB1eqi+NITP1D+nCw9YLRF5+RbL9nOW5UG7Co\ndLX99WFhxBJY8q0uwT/312azpnIZjgtx9roIrf9LVXtwxuOoNNB4xJJ+NM9wLmd1\nVNUaJdg06g6rSTCTQAo2BD71+4MMY7X2/v0aOHtEKnOyBr12NhO/eiDNX8TeyU/k\n7JZM7EBD3PrhldZiu0k=\n-----END CERTIFICATE-----',
        # rubocop:enable Metrics/LineLength
      ].each do |value|
        describe value.inspect do
          it { is_expected.to allow_value(value) }
        end
      end
    end

    describe 'rejects other values' do
      [
        # rubocop:disable Metrics/LineLength
        '-----BEGIN CERTIFICATE REQUEST-----\nMIICsjCCAZoCAQAwbTELMAkGA1UEBhMCQVQxFjAUBgNVBAMMDSouZXhhbXBsZS5j\nb20xETAPBgNVBAcMCFNhbHpidXJnMQ0wCwYDVQQKDAR0ZXN0MREwDwYDVQQIDAhT\nYWx6YnVyZzERMA8GA1UECwwId2lsZGNhcmQwggEiMA0GCSqGSIb3DQEBAQUAA4IB\nDwAwggEKAoIBAQDM4PnosUgvhLGjC6EAhUCuAoQCXsO4C0ac3p9ktemlrBmrAFU2\no2lwOyhncO14PUbqy4Uj+Kw2Fz0M7xvPN5TwtjD9A0lQMZCwoc9RmHF+BipCHZmG\nCrv1D/5hRjS9dM59l1N/7k/3B9SyO/y6vj7NVhbj37rSNTfKuQBZsCnwYfCKgEvo\n7IGtlKgkRzIGHhdHnbIWlAvfoKx0J2icd5VV2g8RjOmKliJmfolwSzYSwbz0mrZU\nJTM2rH/yIcJ98TU+XF3X5AmOMafL0wELi3/7J0a8uLRanDomHSzXxpS5iipunN3e\nC2InK03+sVYNpQw7/Z5LswrHzY6QPZiRv5dfAgMBAAGgADANBgkqhkiG9w0BAQsF\nAAOCAQEAG/C57AZLnTALDAUdDnQTTQgziZ9lTyfIWiZbJphc1Dow+R7Yya9wuFKd\ntWK7hbGkYA2U35R1nH3Evni1NaZlXB4qYtZ3ur62SRnWvRmraW9O+p8korv8jXpf\nV8FPOHjvdO1vXxRLRQA3RcqbMeJLz9ittIDtPIPcGv/CAGQj5spTEAzIiWahB97k\npRgbg9OzbbwRD6tPNWt6GYSpI96G4FInXiLZtj8VLJJb3H1k2ni8wqW10BQIwUOo\nV4PAgcQ2VDryUYPlOWQZ/+u4iUeoutuNVES1eB/UOVgZKcV5I2EZh8kvbcUP4Ox5\ntLZBnrJZXPuGqjv9jDWTi1WevCFIlA==\n-----END CERTIFICATE REQUEST-----',
        # rubocop:enable Metrics/LineLength
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
