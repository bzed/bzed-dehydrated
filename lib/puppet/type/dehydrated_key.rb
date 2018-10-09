# based on https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/type/ssl_pkey.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
Puppet::Type.newtype(:dehydrated_key) do
  desc 'Create a private key for dehydrated.'

  newparam(:path, namevar: true) do
    desc 'Key location, must be absolute.'
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:algorithm) do
    desc "Use the ec parameters with specified 'short name'"
    newvalues(:prime256v1, :secp384r1, :rsa)
    defaultto :rsa

    munge do |val|
      val.to_sym
    end
  end

  newparam(:password) do
    desc 'The optional password for the key'
  end

  newparam(:size) do
    desc 'The key size, used for RSA only.'
    newvalue(/\d+/)
    defaultto 2048

    munge do |val|
      val.to_i
    end
  end
end
