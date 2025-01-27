# frozen_string_literal: true

# idea taken from https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/type/dhparam.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
Puppet::Type.newtype(:dehydrated_dhparam) do
  desc 'DH params for dehydrated'

  newparam(:path, namevar: true) do
    desc 'Absolute pathname of the DH file'
    validate do |value|
      path = Pathname.new(value)
      raise ArgumentError, "Path must be absolute: #{path}" unless path.absolute?
    end
  end

  newparam(:size) do
    desc 'The key size'
    defaultto 2048
    validate do |value|
      size = value.to_i
      raise Puppet::Error, "Size must be an integer >=3: #{value.inspect}" if size < 3 || value.to_s != size.to_s
    end
    munge(&:to_i)
  end
end
