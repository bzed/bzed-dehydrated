# frozen_string_literal: true

# idea taken from https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/provider/x509_request/openssl.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
require 'openssl'
Puppet::Type.type(:dehydrated_csr).provide(:openssl) do
  desc 'Manages certificate signing requests with OpenSSL'

  def self.private_key(resource)
    file = File.read(resource[:private_key])
    begin
      OpenSSL::PKey.read(file, resource[:password])
    rescue OpenSSL::PKey::PKeyError
      false
    end
  end

  def self._parse_san_value(san_value)
    case san_value.tag
    when 2
      san_value.value
    when 7
      case san_value.value.size
      when 4
        san_value.value.unpack('C*').join('.')
      when 16
        san_value.value.unpack('n*').map { |o| format('%X', o) }.join(':')
      end
    end
  end

  def self.check_sans(resource)
    if File.exist?(resource[:path])
      request = OpenSSL::X509::Request.new(File.read(resource[:path]))
      ext_req = request.attributes.find do |a|
        a.oid == 'extReq'
      end

      csr_alt_names = if ext_req
                        san_values = ext_req.value.map do |ext_req_v|
                          san = ext_req_v.find do |v|
                            v.value[0].value == 'subjectAltName'
                          end
                          san.value[1] if san
                        end
                        if san_values
                          san_values = OpenSSL::ASN1.decode(san_values[0].value)

                          san_values.map do |v|
                            _parse_san_value(v)
                          end
                        else
                          []
                        end
                      else
                        []
                      end

      configured_alt_names = [resource[:common_name], resource[:subject_alternative_names]]
      configured_alt_names.flatten!.uniq!
      configured_alt_names.sort == csr_alt_names.sort
    else
      false
    end
  end

  def self.check_private_key(resource)
    if File.exist?(resource[:path]) && File.exist?(resource[:private_key])
      request = OpenSSL::X509::Request.new(File.read(resource[:path]))
      priv = private_key(resource)
      return false unless priv

      request.verify(priv)
    else
      false
    end
  end

  def self.create_subject(resource)
    name = OpenSSL::X509::Name.new
    # name.add_entry('serialNumber', serial_number) unless resource[:serial_number].blank?
    name.add_entry('C', resource[:country]) if resource[:country] && resource[:country] != ''
    name.add_entry('ST', resource[:state]) if resource[:state] && resource[:state] != ''
    name.add_entry('L', resource[:locality]) if resource[:locality] && resource[:locality] != ''
    name.add_entry('O', resource[:organization]) if resource[:organization] && resource[:organization] != ''
    name.add_entry('OU', resource[:organizational_unit]) if resource[:organizational_unit] && resource[:organizational_unit] != ''
    name.add_entry('CN', resource[:common_name])
    name.add_entry('emailAddress', resource[:email_address]) if resource[:email_address] && resource[:email_address] != ''
    name
  end

  def self.check_subject(resource)
    if File.exist?(resource[:path])
      request = OpenSSL::X509::Request.new(File.read(resource[:path]))
      old_name = request.subject
      new_name = create_subject(resource)
      old_name == new_name
    else
      false
    end
  end

  def self.create_san_attribute(subject_alternative_names)
    raise Puppet::Error, 'subject_alternative_names must be an array!' unless subject_alternative_names.is_a?(Array)

    factory = OpenSSL::X509::ExtensionFactory.new
    dns_subject_alternative_names = subject_alternative_names.map do |san|
      "DNS:#{san}"
    end
    dns_subject_alternative_names_list = dns_subject_alternative_names.join(',')
    ext = factory.create_extension(
      'subjectAltName',
      dns_subject_alternative_names_list,
      false
    )
    ext_set = OpenSSL::ASN1::Set.new([OpenSSL::ASN1::Sequence.new([ext])])
    OpenSSL::X509::Attribute.new('extReq', ext_set)
  end

  def self.create_x509_csr(subject, attributes, private_key, digest)
    if private_key.instance_of? OpenSSL::PKey::EC
      if private_key.respond_to?(:public_to_der)
        pubkey_der = private_key.public_to_der
      elsif private_key.public_key.respond_to?(:to_der)
        pubkey_der = private_key.public_key.to_der
      else
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
          pubkey_der = OpenSSL::PKey::EC.new(asn1.to_der)
        rescue StandardError
          raise Puppet::Error, 'Your ruby version is too old or your openssl broken, it does not support EC keys properly'
        end
      end
      pubkey = OpenSSL::PKey::EC.new pubkey_der
    else
      pubkey = private_key.public_key
    end
    raise Puppet::Error, 'Pubkey has no public parts' unless pubkey.public?
    raise Puppet::Error, 'Pubkey still has private parts' if pubkey.private?

    request = OpenSSL::X509::Request.new
    request.subject = subject
    attributes.each do |attribute|
      request.add_attribute(attribute)
    end
    request.public_key = pubkey
    openssl_digest = OpenSSL::Digest.new(digest)
    request.sign(private_key, openssl_digest)
    request.to_pem
  end

  def exists?
    exists = begin
      if Pathname.new(resource[:path]).exist?
        request = OpenSSL::X509::Request.new(File.read(resource[:path]))
        if request
          true
        else
          false
        end
      else
        false
      end
    rescue OpenSSL::X509::RequestError
      false
    end
    if exists && resource[:force]
      self.class.check_private_key(resource) &&
        self.class.check_sans(resource) &&
        self.class.check_subject(resource)
    else
      exists
    end
  end

  def create
    subject = self.class.create_subject(resource)
    subject_alternative_names = if resource[:subject_alternative_names].nil? || resource[:subject_alternative_names].empty?
                                  [resource[:common_name]]
                                elsif resource[:subject_alternative_names].include?(resource[:common_name])
                                  resource[:subject_alternative_names]
                                else
                                  [resource[:common_name]] + resource[:subject_alternative_names]
                                end
    attributes = [self.class.create_san_attribute(subject_alternative_names)]
    private_key = self.class.private_key(resource)
    return false unless private_key

    digest = resource[:digest]
    x509_csr = self.class.create_x509_csr(subject, attributes, private_key, digest)
    File.write(resource[:path], x509_csr)
  end

  def destroy
    Pathname.new(resource[:path]).delete
  end
end
