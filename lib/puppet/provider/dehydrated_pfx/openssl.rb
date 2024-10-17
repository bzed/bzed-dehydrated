require 'pathname'
require 'openssl'
Puppet::Type.type(:dehydrated_pfx).provide(:openssl) do
  desc 'Manages pkcs12/pfx file creation with OpenSSL'

  def self.certificate(filename, read_array)
    file = File.read(filename)
    if read_array
      file.split('-----BEGIN ').select { |cert| cert =~ %r{^CERTIFICATE.*} }.map do |cert|
        OpenSSL::X509::Certificate.new('-----BEGIN ' + cert)
      end
    else
      OpenSSL::X509::Certificate.new(file)
    end
  end

  def self.private_key(resource)
    key = File.read(resource[:private_key])
    begin
      OpenSSL::PKey.read(key, resource[:key_password])
    rescue OpenSSL::PKey::PKeyError
      false
    end
  end

  def exists?
    if File.exist?(resource[:path])
      begin
        # use binary mode as ruby is picky on windows.
        pfx_data = File.open(resource[:path], 'rb') { |f| f.read }
        pfx = OpenSSL::PKCS12.new(pfx_data)
        ca = self.class.certificate(resource[:ca], true)
        cert = self.class.certificate(resource[:certificate], false)
        key = self.class.private_key(resource)
        return false unless key
        pfx_ca_serials = pfx.ca_certs.map { |pfx_cert| pfx_cert.serial.to_s }.sort
        ca_serials = ca.map { |pfx_cert| pfx_cert.serial.to_s }.sort
        pfx_ca_serials == ca_serials && \
          pfx.certificate.serial.to_s == cert.serial.to_s && \
          key.to_pem == pfx.key.to_pem
      rescue OpenSSL::PKCS12::PKCS12Error
        false
      rescue OpenSSL::X509::CertificateError
        false
      rescue OpenSSL::PKey::ECError
        false
      rescue OpenSSL::PKey::RSAError
        false
      end
    else
      false
    end
  end

  def create
    ca = self.class.certificate(resource[:ca], true)
    cert = self.class.certificate(resource[:certificate], false)
    key = self.class.private_key(resource)

    return false unless key

    begin
      pfx = OpenSSL::PKCS12.create(
        resource[:password],
        resource[:pkcs12_name],
        key,
        cert,
        ca,
      )
    rescue OpenSSL::PKCS12::PKCS12Error
      File.delete(resource[:path]) if File.exist?(resource[:path])
      false
    rescue => e
      raise Puppet::Error, "Unknown error while creating pfx file: #{e.class} - #{e.message}"
    end

    # use binary mode as windows is extra picky.
    File.open(resource[:path], 'wb') { |f| f.write(pfx.to_der) }
  end

  def destroy
    Pathname.new(resource[:path]).delete
  end
end
