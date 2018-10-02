require 'pathname'
Puppet::Type.newtype(:ecparam) do
  desc 'Create an ec private key.'

  newparam(:path, namevar: true) do
    desc 'Key location, must be absolute.'
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:short_name) do
    desc "Use the ec parameters with specified 'short name'"
    newvalues :prime256v1, :secp384r1
    defaultto :secp384r1

    munge do |val|
      val.to_sym
    end
  end

  newparam(:password) do
    desc 'The optional password for the key'
  end
end
