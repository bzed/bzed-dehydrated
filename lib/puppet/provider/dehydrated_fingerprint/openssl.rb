# frozen_string_literal: true

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
      private_key = OpenSSL::PKey.read(key, password)
    rescue OpenSSL::PKey::PKeyError
      return false
    end
    if private_key.respond_to?(:public_to_der)
      pubkey_der = private_key.public_to_der
    elsif private_key.public_key.respond_to?(:to_der)
      pubkey_der = private_key.public_key.to_der
    elsif private_key.instance_of? OpenSSL::PKey::EC
      begin
        asn1 = OpenSSL::ASN1::Sequence(
          [
            OpenSSL::ASN1::Sequence(
              [
                OpenSSL::ASN1::ObjectId('id-ecPublicKey'),
                OpenSSL::ASN1::ObjectId(private_key.public_key.group.curve_name),
              ]
            ),
            OpenSSL::ASN1::BitString(private_key.public_key.to_octet_string(:uncompressed)),
          ]
        )
        pubkey_der = asn1.to_der
      rescue StandardError
        raise Puppet::Error, 'Failed to create public key in DER format from EC key'
      end
    else
      raise Puppet::Error, 'Your ruby version is too old or your openssl broken, it does not support EC keys properly'
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
      fp = self.class.get_fingerprint(File.read(resource[:private_key]), resource[:password]) if Pathname.new(resource[:private_key]).exist?
      f.write(fp || 'null')
    end
  end

  def destroy
    Pathname.new(resource[:path]).delete
  end
end
