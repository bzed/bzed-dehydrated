require 'pathname'

Puppet::Type.newtype(:dehydrated_pfx) do
  desc 'pkcs12 / pfx files for dehydrated'

  ensurable

  newparam(:path, namevar: true) do
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:password) do
    desc 'The optional password for the pkcs12 container'
  end

  newparam(:key_password) do
    desc 'The optional password for the private key'
  end

  newparam(:certificate) do
    desc 'The path of the certificate to put into the pkcs12 container'
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise Puppet::Error, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:ca) do
    desc 'The path of the ca certificates to put into the pkcs12 container'
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise Puppet::Error, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:name) do
    desc 'A string describing the key / pkcs12 container'
    defaultto do
      path = Pathname.new(@resource[:path])
      "#{path.basename(path.extname)}"
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
        raise Puppet::Error, "Path must be absolute: #{path}"
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
