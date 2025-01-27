# frozen_string_literal: true

require 'pathname'

Puppet::Type.newtype(:dehydrated_pfx) do
  desc 'pkcs12 / pfx files for dehydrated'

  newparam(:path, namevar: true) do
    desc 'Absolute path of the pfx file'
    validate do |value|
      path = Pathname.new(value)
      raise ArgumentError, "Path must be absolute: #{path}" unless path.absolute?
    end
  end

  newparam(:password) do
    desc 'The optional password for the pkcs12 container'
    defaultto do
      nil
    end
  end

  newparam(:key_password) do
    desc 'The optional password for the private key'
  end

  newparam(:certificate) do
    desc 'The path of the certificate to put into the pkcs12 container'
    validate do |value|
      path = Pathname.new(value)
      raise Puppet::Error, "Path must be absolute: #{path}" unless path.absolute?
    end
  end

  newparam(:ca) do
    desc 'The path of the ca certificates to put into the pkcs12 container'
    validate do |value|
      path = Pathname.new(value)
      raise Puppet::Error, "Path must be absolute: #{path}" unless path.absolute?
    end
  end

  newparam(:pkcs12_name) do
    desc 'A string describing the key / pkcs12 container'
    defaultto do
      path = Pathname.new(@resource[:path])
      path.basename(path.extname).to_s
    end
  end

  newparam(:private_key) do
    desc 'absolute path of the private keyfile'
    defaultto do
      path = Pathname.new(@resource[:path])
      "#{path.dirname}/#{path.basename(path.extname)}.key"
    end
    validate do |value|
      path = Pathname.new(value)
      raise Puppet::Error, "Path must be absolute: #{path}" unless path.absolute?
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
