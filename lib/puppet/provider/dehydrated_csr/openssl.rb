# idea taken from https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/provider/x509_request/openssl.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
require 'openssl'
Puppet::Type.type(:dehydrated_csr).provide(:openssl) do
  desc 'Manages certificate signing requests with OpenSSL'

  def self.private_key(resource)
    file = File.read(resource[:private_key])
    if resource[:algorithm] == :rsa
      OpenSSL::PKey::RSA.new(file, resource[:password])
    elsif resource[:algorithm] == :prime256v1 || resource[:algorithm] == :secp384r1
      OpenSSL::PKey::EC.new(file, resource[:password])
    else
      raise Puppet::Error, "Unknown algorithm type '#{resource[:algorithm]}'"
    end
  end

  def self.check_sans(resource)
    ext_req = request.attributes.find do |a|
      a.oid == 'extReq'
    end

    san_value = ext_req.value.map do |ext_req_v|
      san = ext_req_v.find do |v|
        v.value[0].value == 'subjectAltName'
      end
      if san
        san.value[1]
      end
    end
    san_value = OpenSSL::ASN1.decode(san_value[0].value)

    csr_alt_names = san_value.map do |v|
      case v.tag
      when 2
        v.value
      when 7
        case v.value.size
        when 4
          v.value.unpack('C*').join('.')
        when 16
          v.value.unpack('n*').map { |o| '%X' % o }.join(':')
        end
      end
    end

    configured_alt_names = [resource[:common_name], resource[:subject_alternative_names]]
    configured_alt_names.flatten!.uniq!
    configured_alt_names.sort == csr_alt_names.sort
  end

  def self.check_private_key(resource)
    request = OpenSSL::X509::Request.new(File.read(resource[:path]))
    priv = private_key(resource)
    request.verify(priv)
  end

  def self.create_subject(resource)
    name = OpenSSL::X509::Name.new
    # lets stay with CN for now
    # other entries can be added propely later.
    # name.add_entry('serialNumber', serial_number) unless resource[:serial_number].blank?
    # name.add_entry('C', country) unless resource[:country].blank?
    # name.add_entry('ST', state) unless resource[:state].blank?
    # name.add_entry('L', locality) unless resource[:locality].blank?
    # name.add_entry('O', organization) unless resource[:organization].blank?
    # name.add_entry('OU', organizational_unit) unless resource[:organizational_unit].blank?
    name.add_entry('CN', resource[:common_name])
    # name.add_entry('emailAddress', email_address) unless resource[:email_address].blank?
    name
  end

  def self.create_san_attribute(subject_alternative_names)
    unless subject_alternative_names.is_a?(Array)
      raise Puppet::Error, 'subject_alternative_names must be an array!'
    end

    factory = OpenSSL::X509::ExtensionFactory.new
    dns_subject_alternative_names = subject_alternative_names.map do |san|
      "DNS:#{san}"
    end
    dns_subject_alternative_names_list = dns_subject_alternative_names.join(',')

    ext = factory.create_ext(
      'subjectAltName',
      dns_subject_alternative_names_list,
      false,
    )
    ext_set = OpenSSL::ASN1::Set([OpenSSL::ASN1::Sequence([ext])])
    OpenSSL::X509::Attribute.new('extReq', ext_set)
  end

  def self.create_x509_csr(subject, attributes, private_key, digest)
    request = OpenSSL::X509::Request.new
    request.subject = subject
    request.attributes = attributes unless @attributes.nil?
    request.public_key = private_key.public_key
    openssl_digest = OpenSSL::Digest.new(digest)
    request.sign(private_key, openssl_digest)
    request.to_pem
  end

  def exists?
    (
     Pathname.new(resource[:path]).exist? ||
     (resource[:force] && !self.class.check_private_key(resource)) ||
     (resource[:force] && !self.class.check_sans(resource))
    )
  end

  def create
    subject = self.class.create_subject(resource)
    subject_alternative_names = if resource[:subject_alternative_names].blank?
                                  [resource[:common_name]]
                                elsif resource[:subject_alternative_names].include?(resource[:common_name])
                                  resource[:subject_alternative_names]
                                else
                                  [resource[:common_name]] + resource[:subject_alternative_names]
                                end
    attributes = [self.class.create_san_attribute(subject_alternative_names)]
    private_key = self.class.private_key(resource)
    digest = resource[:digest]
    x509_csr = self.class.create_x509_csr(subject, attributes, private_key, digest)
    File.write(resource[:path], x509_csr)
  end

  def destroy
    Pathname.new(resource[:path]).delete
  end
end
