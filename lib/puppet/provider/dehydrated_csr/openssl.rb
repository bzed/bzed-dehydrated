# idea taken from https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/provider/x509_request/openssl.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
Puppet::Type.type(:dehydrated_csr).provide(:openssl) do
  desc 'Manages certificate signing requests with OpenSSL'

  commands :openssl => 'openssl'

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

  def self.check_template(resource)
    request = OpenSSL::X509::Request.new(File.read(resource[:path]))
    config = OpenSSL::Config.new(resource[:template])
    configured_alt_names = config['alt_names'].values

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
    end[0]
    san_value = OpenSSL::ASN1.decode(san_value.value)

    csr_alt_names = san_value.map do |v|
      case v.tag
      when 2
        v.value
      when 7
        case v.value.size
        when 4
          v.value.unpack('C*').join('.')
        when 16
          v.value.unpack('n*').map { |o| sprintf("%X", o) }.join(':')
        end
      end
    end

    configured_alt_names.sort == csr_alt_names.sort
  end

  def self.check_private_key(resource)
    request = OpenSSL::X509::Request.new(File.read(resource[:path]))
    priv = self.private_key(resource)
    request.verify(priv)
  end

  def exists?
    if Pathname.new(resource[:path]).exist?
      if resource[:force] and !self.class.check_private_key(resource)
        return false
      end
      if resource[:force] and !self.class.check_template(resource)
        return false
      end
      return true
    else
      return false
    end
  end

  def create
    cmd_args = [
      'req', '-new',
      '-key', resource[:private_key],
      '-config', resource[:template],
      '-out', resource[:path]
    ]

    if resource[:password]
      cmd_args.push('-passin')
      cmd_args.push("pass:#{resource[:password]}")
    end

    if not resource[:encrypted]
      cmd_args.push('-nodes')
    end

    openssl(*cmd_args)
  end

  def destroy
    Pathname.new(resource[:path]).delete
  end
end
