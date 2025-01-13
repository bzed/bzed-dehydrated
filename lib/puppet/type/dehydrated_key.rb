# frozen_string_literal: true

# based on https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/type/ssl_pkey.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
Puppet::Type.newtype(:dehydrated_key) do
  desc 'Create a private key for dehydrated.'

  ensurable

  newparam(:path, namevar: true) do
    desc 'Key location, must be absolute.'
    validate do |value|
      path = Pathname.new(value)
      raise Puppet::Error, "Path must be absolute: #{path}" unless path.absolute?
    end
  end

  newparam(:algorithm) do
    desc 'Algorithm to use for Key generation, supported: prime256v1, secp384r1, rsa'
    newvalues(:prime256v1, :secp384r1, :rsa)
    defaultto :rsa

    munge(&:to_sym)
  end

  newparam(:password) do
    desc 'The optional password for the key'
  end

  newparam(:size) do
    desc 'The key size, used for RSA only.'
    defaultto 3072

    validate do |value|
      raise Puppet::Error, 'The key size must be an integer.' unless (value.to_i.to_s == value) || (value.to_i == value)
      raise Puppet::Error, 'Only key sizes >= 512 and <= 16384 are supported.' unless value.to_i >= 512 && value.to_i <= 16_384
    end

    munge(&:to_i)
  end
end
