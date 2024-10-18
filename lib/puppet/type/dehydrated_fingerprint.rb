require 'pathname'
Puppet::Type.newtype(:dehydrated_fingerprint) do
  desc 'Create a fingerprint file key for a private key file.'

  ensurable

  newparam(:path, namevar: true) do
    desc 'Fingerprint location, must be absolute.'
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise Puppet::Error, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:private_key) do
    desc 'Key location, must be absolute.'
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise Puppet::Error, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:password) do
    desc 'The optional password for the key'
  end

  autorequire(:dehydrated_key) do
    self[:private_key]
  end
end
