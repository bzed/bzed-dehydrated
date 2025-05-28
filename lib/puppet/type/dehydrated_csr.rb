# frozen_string_literal: true

# based on https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/type/x509_request.rb
# Apache License, Version 2.0, January 2004

require 'pathname'

Puppet::Type.newtype(:dehydrated_csr) do
  desc 'CSRs for dehydrated'

  ensurable

  newparam(:path, namevar: true) do
    desc 'Absolute path of the CSR location'
    validate do |value|
      path = Pathname.new(value)
      raise ArgumentError, "Path must be absolute: #{path}" unless path.absolute?
    end
  end

  newparam(:force, boolean: true) do
    desc 'Whether to replace the certificate if the private key or CommonName/SANs mismatches'
    newvalues(true, false)
    defaultto false
  end

  newparam(:password) do
    desc 'The optional password for the private key'
  end

  newparam(:private_key) do
    desc 'Absolute path of the key we want to use'
    defaultto do
      path = Pathname.new(@resource[:path])
      "#{path.dirname}/#{path.basename(path.extname)}.key"
    end
    validate do |value|
      path = Pathname.new(value)
      raise Puppet::Error, "Path must be absolute: #{path}" unless path.absolute?
    end
  end

  newparam(:algorithm) do
    desc 'The algorithm to use, supported: rsa, secp384r1, prime256v1'
    newvalues(:prime256v1, :secp384r1, :rsa)
    defaultto :rsa

    munge(&:to_sym)
  end

  newparam(:common_name) do
    desc 'The common name for the csr'
    validate do |value|
      raise Puppet::Error, 'A common name is always required' if value.nil? || !value.is_a?(String)
    end
  end

  newparam(:digest) do
    desc 'Digest used while signing the CSR, defaults to SHA512'
    defaultto :SHA512
    validate do |value|
      raise Puppet::Error, "Unknown digest #{value}" unless %r{^(MD[245]|SHA(|-?(1|224|256|384|512)))$}.match?(value)
    end
  end

  newparam(:subject_alternative_names) do
    desc 'SANs to request'
    defaultto []
    validate do |value|
      raise Puppet::Error, 'subject_alternative_names must be an array!' unless value.is_a?(Array)
    end

    munge(&:uniq)
  end

  newparam(:country) do
    desc 'country part of the certificate name'
    validate do |value|
      raise Puppet::Error, 'valid ssl country name (usually two capital letters) required' if value && !value.empty? && !%r{^([A-Z]{2}|(COM|EDU|GOV|INT|MIL|NET|ORG)|ARPA)$}.match?(value)
    end
  end

  newparam(:locality) do
    desc 'locality part of the certificate name'
  end

  newparam(:organization) do
    desc 'locality part of the certificate name'
  end

  newparam(:state) do
    desc 'state part of the certificate name'
  end

  newparam(:organizational_unit) do
    desc 'organizational_unit part of the certificate name'
  end

  newparam(:email_address) do
    desc 'emailAddress part of the certificate name'
    validate do |value|
      if value && !value.blank? && !%r{\A[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@
(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z}.match?(value)
        raise Puppet::Error, 'email_address should be valid!'
      end
    end
  end

  autorequire(:dehydrated_key) do
    self[:private_key]
  end

  autorequire(:file) do
    self[:private_key]
  end

  def refresh
    provider.create
  end
end
