# based on https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/type/x509_request.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
Puppet::Type.newtype(:dehydrated_csr) do
  desc 'CSRs for dehydrated'

  ensurable

  newparam(:path, namevar: true) do
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
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
    defaultto do
      path = Pathname.new(@resource[:path])
      "#{path.dirname}/#{path.basename(path.extname)}.key"
    end
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise Puppet::Error, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:algorithm) do
    desc 'The algorithm to use, supported: rsa, secp384r1, prime256v1'
    newvalues(:prime256v1, :secp384r1, :rsa)
    defaultto :rsa

    munge do |val|
      val.to_sym
    end
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
      raise Puppet::Error, "Unknown digest #{value}" if value !~ %r{^(MD[245]|SHA(|-?(1|224|256|384|512)))$}
    end
  end

  newparam(:subject_alternative_names) do
    desc 'SANs to request'
    defaultto []
    validate do |value|
      raise Puppet::Error, 'subject_alternative_names must be an array!' unless value.is_a?(Array)
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
