# based on https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/provider/ssl_pkey/openssl.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
require 'openssl'
require 'json'

Puppet::Type.type(:dehydrated_fingerprint).provide(:openssl) do
  desc 'Manages private key fingerprints for dehydrated with OpenSSL'

  def self.dirname(resource)
    resource[:path].dirname
  end

  def self.get_fingerprint(key, password)
    begin
      privkey = OpenSSL::PKey.read(key, password)
    rescue OpenSSL::PKey::PKeyError
      return false
    end
    begin
      pubkey_der = privkey.public_to_der
    rescue NoMethodError
      pubkey_der = privkey.public_key.to_der
    end
    digests = {
      sha256: OpenSSL::Digest::SHA256.new(pubkey_der).to_s,
    }
    JSON.generate(digests)
  end

  def exists?
    return false unless Pathname.new(resource[:path]).exist?
    key = File.read(resource[:private_key])
    return false if key.empty?
    return false if key.include?('ENCRYPTED') && !resource[:password]
    fingerprint = self.class.get_fingerprint(key, resource[:password])
    old_fingerprint = File.read(resource[:path])
    fingerprint == old_fingerprint
  end

  def create
    File.open(resource[:path], 'w') do |f|
      if Pathname.new(resource[:private_key]).exist?
        fp = self.class.get_fingerprint(File.read(resource[:private_key]), resource[:password])
      end
      f.write(fp || 'null')
    end
  end

  def destroy
    Pathname.new(resource[:path]).delete
  end
end
