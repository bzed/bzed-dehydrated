# based on https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/type/x509_request.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
Puppet::Type.newtype(:dehydrated_csr) do
  desc 'CSRs for dehydrated'

  ensurable

  newparam(:path, :namevar => true) do
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:force, :boolean => true) do
    desc 'Whether to replace the certificate if the private key or CommonName/SANs mismatches'
    newvalues(:true, :false)
    defaultto false
  end

  newparam(:password) do
    desc 'The optional password for the private key'
  end

  newparam(:template) do
    defaultto do
      path = Pathname.new(@resource[:path])
      "#{path.dirname}/#{path.basename(path.extname)}.cnf"
    end
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        fail "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:private_key) do
    defaultto do
      path = Pathname.new(@resource[:path])
      "#{path.dirname}/#{path.basename(path.extname)}.key"
    end
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        fail "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:algorithm) do
    desc 'The algorithm to use, supported: rsa, secp384r1, prime256v1'
    validate do |value|
        fail 'Supported algorithms: rsa, secp384r1, prime256v1' if value !~ %r{^(rsa|secp384r1|prime256v1)$}
    end
    defaultto :rsa
  end

  newparam(:encrypted, :boolean => true) do
    desc 'Whether to generate the key unencrypted. This is needed by some applications like OpenLDAP'
    newvalues(:true, :false)
    defaultto true
  end

  autorequire(:x509_cert) do
    path = Pathname.new(self[:private_key])
    "#{path.dirname}/#{path.basename(path.extname)}"
  end

  autorequire(:file) do
    self[:private_key]
  end

  def refresh
    provider.create
  end
end
