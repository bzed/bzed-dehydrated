# frozen_string_literal: true

# based on https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/provider/ssl_pkey/openssl.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
require 'openssl'

Puppet::Type.type(:dehydrated_key).provide(:openssl) do
  desc 'Manages private keys for dehydrated with OpenSSL'

  def self.dirname(resource)
    resource[:path].dirname
  end

  def self.generate_key(resource)
    if resource[:algorithm] == :rsa
      OpenSSL::PKey::RSA.new(resource[:size])
    elsif resource[:algorithm] == :prime256v1 || resource[:algorithm] == :secp384r1
      OpenSSL::PKey::EC.generate(resource[:algorithm].to_s)
    else
      raise Puppet::Error, "Don't know how to handle #{resource[:algorithm]} keys."
    end
  end

  def self.to_pem(resource, key)
    if resource[:password]
      cipher = OpenSSL::Cipher.new('aes256')
      key.to_pem(cipher, resource[:password])
    else
      key.to_pem
    end
  end

  def exists?
    return false unless Pathname.new(resource[:path]).exist?

    key = File.read(resource[:path])
    return false if key.empty?
    return false if key.include?('ENCRYPTED') && !resource[:password]

    begin
      key = OpenSSL::PKey.read(key, resource[:password])
      true if key
    rescue OpenSSL::PKey::PKeyError # wrong password or buggy key
      false
    end
  end

  def create
    key = self.class.generate_key(resource)
    pem = self.class.to_pem(resource, key)
    File.write(resource[:path], pem)
  end

  def destroy
    Pathname.new(resource[:path]).delete
  end
end
