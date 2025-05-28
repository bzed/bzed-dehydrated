# frozen_string_literal: true

require 'facter'
require 'json'
require 'openssl'

Facter.add(:dehydrated_config) do
  setcode do
    puppet_vardir = Facter.value(:puppet_vardir)
    configfile = File.join(puppet_vardir, 'bzed-dehydrated', 'config.json')

    JSON.parse(File.read(configfile)) if File.exist?(configfile)
  end
end

def get_cert_serial(crt)
  raw_cert = File.read(crt)
  begin
    cert = OpenSSL::X509::Certificate.new raw_cert
    cert.serial.to_s
  rescue OpenSSL::X509::CertificateError
    ''
  end
end

def get_cert_fingerprints(crt)
  raw_cert = File.read(crt)
  cert = OpenSSL::X509::Certificate.new raw_cert
  der = cert.to_der

  {
    sha1: OpenSSL::Digest::SHA1.new(der).to_s,
    sha256: OpenSSL::Digest::SHA256.new(der).to_s,
  }
end

Facter.add(:dehydrated_domains) do
  setcode do
    puppet_vardir = Facter.value(:puppet_vardir)
    domainsfile = File.join(puppet_vardir, 'bzed-dehydrated', 'domains.json')
    config = Facter.value(:dehydrated_config)
    if config && File.exist?(domainsfile)
      ret = JSON.parse(File.read(domainsfile))
      ret.each do |dn, dnconfig|
        base_filename = dnconfig['base_filename']
        next unless config

        csr_dir = config['csr_dir']
        crt_dir = config['crt_dir']
        key_dir = config['key_dir']

        # CSR
        csr = File.join(csr_dir, "#{base_filename}.csr")
        ret[dn]['csr'] = if File.exist?(csr)
                           File.read(csr).strip
                         else
                           ''
                         end
        # fingerprints
        key = File.join(key_dir, "#{base_filename}.key")
        fingerprint = "#{key}.fingerprint"
        crt = File.join(crt_dir, "#{base_filename}.crt")
        if File.exist?(crt)
          ret[dn]['crt_serial'] = get_cert_serial(crt)
          ret[dn]['crt_fingerprints'] = get_cert_fingerprints(crt)
        end
        ret[dn]['fingerprints'] = JSON.parse(File.read(fingerprint)) if File.exist?(fingerprint)

        ca = File.join(crt_dir, "#{base_filename}_ca.pem")

        # DH
        dh = File.join(crt_dir, "#{base_filename}.dh")

        ret[dn]['ready_for_merge'] = File.exist?(csr) &&
                                     File.exist?(crt) &&
                                     File.exist?(key) &&
                                     File.exist?(dh) &&
                                     File.exist?(ca)
      end
      ret
    else
      {}
    end
  end
end
