require 'facter'
require 'json'
require 'openssl'
require 'base64'

def get_ocsp(ocsp)
  if File.exist?(ocsp)
    Base64.strict_encode64(File.read(ocsp))
  else
    nil
  end
end

def get_file(filename)
  if File.exist?(filename)
    File.read(filename)
  else
    nil
  end
end

def get_certificate(crt, old_serial)
  if File.exist?(crt)
    raw_cert = File.read(crt)
    begin
      cert = OpenSSL::X509::Certificate.new raw_cert
      serial = cert.serial.to_i
      if serial == old_serial
        nil
      else
        raw_cert
      end
    rescue OpenSSL::X509::CertificateError
      nil
    end
  else
    nil
  end
end

def handle_requests(config)
  if config
    requests = JSON.parse(File.read(config['dehydrated_requests_config']))
    dehydrated_puppetmaster = config['dehydrated_puppetmaster']
    dehydrated_host = config['dehydrated_host']

    if dehydrated_puppetmaster != dehydrated_host
      requests.each do |request_fqdn, certificate_requests|
        certificate_requests.each do |dn, certificate_config|
          base_filename = certificate_config['base_filename']
          crt_serial = certificate_config['crt_serial']
          request_base_dir = certificate_config['request_base_dir']

          crt_file = "#{request_base_dir}/#{base_filename}.crt"
          crt = get_certificate(crt_file, crt_serial)
          requests[request_fqdn][dn]['crt'] = get_certificate(crt_file, crt_serial)
          if crt
            ca_file = "#{request_base_dir}/#{base_filename}_ca.pem"
            requests[request_fqdn][dn]['ca'] = get_file(ca_file)
          end
          ocsp_file = "#{crt_file}.ocsp"
          requests[request_fqdn][dn]['ocsp'] = get_ocsp(ocsp_file)
        end
      end
    end
    requests
  else
    nil
  end
end

Facter.add(:dehydrated_certificates) do
  setcode do
    config = Facter.value(:dehydrated_config)
    if config.nil? or config.empty?
      nil
    else
      fqdn = Facter.value(:fqdn)
      dehydrated_host = config['dehydrated_host']
      if fqdn != dehydrated_host
        nil
      else
        handle_requests(config)
      end
    end
  end
end
