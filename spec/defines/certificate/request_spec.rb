# frozen_string_literal: true

require 'spec_helper'

describe 'dehydrated::certificate::request' do
  let(:title) { 'test.example.com-test.example.com' }
  let(:params) do
    {
      'request_fqdn' => 'test.example.com',
      'dn' => 'test.example.com',
      'config' => {
        'subject_alternative_names' => [],
        'base_filename' => 'test.example.com',
        'csr' => '-----BEGIN CERTIFICATE REQUEST-----\nMIICsTCCAZkCAQAwbDELMAkGA1UEBhMCQVQxGTAXBgNVBAMMEHRlc3QuZXhhbXBs\nZS5jb20xETAPBgNVBAcMCFNhbHpidXJnMQ0wCwYDVQQKDAR0ZXN0MREwDwYDVQQI\nDAhTYWx6YnVyZzENMAsGA1UECwwEdGVzdDCCASIwDQYJKoZIhvcNAQEBBQADggEP\nADCCAQoCggEBAJf++476VCppDLm0gi56XrXZFguhYd98fv3w7FsJezHI3I/kfudX\nvEcAAhLA5QqYzCgJbd8qWLtBzewl1hsufhg9bzgST8X7CEShqDB+uZcaaD/amMSG\nVHX/UhpzMb9b22N0oXVaNdeh5QER/VZOk/oJrVQLcaXM50Gu38f8VStMJa+Hw+aK\ntqunJYyKE1gf1BNy/23mJHf2rLC+Gokei1hfjNerkExi9xXBeSfgCqCUEa45wJ4Z\n1DxqaiDCrIWL+iVk2UeOig6bxXsViJGur/6HTABoPmNYAdU+NDaA3t7tluGvM3Y7\n0Uk1BqdrK0yT45AN8qqLcJOeVyC02TGIhGkCAwEAAaAAMA0GCSqGSIb3DQEBCwUA\nA4IBAQBM+JjmC8cGDm4bt5D7NQMkyXlq7AYrCO6pfQb4CMqHA5tl0yixwN+0JcGW\n2viF+8pH5EnMpra9SQGIvbNzV6Vm+EHfoHzQdKDcBD/RJG62cVDxKhRNxEvBwslT\nXaIrcP4dliRLZ7J22xaHH0GXb6kFbnIva7mgfVf1+iJcJ/WE/8/sS/HaTLSYdNTY\ndvT2iaHmUWOpWzqGvlHe7a2iIxMNtQrtUixAit9heoZurRKYkY3GhX0iojiX0wVH\nntEs3oIIvunPavD1orfDzwYKJg5qJly/oI/ZsAKaf/xQhzg0p7sB5O2A7pk6OV/a\nisoMFazQwmz5JpKh8OlsCwUMPwKL\n-----END CERTIFICATE REQUEST-----',
        'crt_serial' => '',
        'dehydrated_hook' => 'dns-01.sh',
        'dehydrated_environment' => {},
        'letsencrypt_ca' => 'v2-staging',
      },
      'dehydrated_host' => 'my.puppetserver.example.com',
    }
  end

  context 'check for fail' do
    it { is_expected.to compile.and_raise_error(%r{Do not instantiate this define}) }
  end
end
