# idea taken from https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/type/dhparam.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
Puppet::Type.newtype(:dhparam) do
  desc 'A Diffie Helman parameter file'

  ensurable

  newparam(:path, :namevar => true) do
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:size) do
    desc 'The key size'
    defaultto 2048
    validate do |value|
      size = value.to_i
      if size < 3 || value.to_s != size.to_s
        raise Puppet::Error, "Size must be an integer >=3: #{value.inspect}"
      end
    end
    munge do |value|
      value.to_i
    end
  end

end
