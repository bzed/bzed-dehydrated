require 'facter'
require 'json'
require 'openssl'

Facter.add(:dehydrated_config) do
  setcode do
    puppet_vardir = Facter.value(:puppet_vardir)
    configfile = File.join(puppet_vardir, 'bzed-dehydrated', 'config.json')

    if File.exist?(configfile)
      JSON.parse(File.read(configfile))
    else
      nil
    end
  end
end

def get_cert_serial(crt)
  if File.exist?(crt)
    raw_cert = File.read(crt)
    begin
      cert = OpenSSL::X509::Certificate.new raw_cert
      cert.serial.to_s
    rescue OpenSSL::X509::CertificateError
      ''
    end
  else
    ''
  end
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
        unless config
          next
        end

        csr_dir = config['csr_dir']
        crt_dir = config['crt_dir']

        # CSR
        csr = File.join(csr_dir, "#{base_filename}.csr")
        ret[dn]['csr'] = if File.exist?(csr)
                           File.read(csr).strip
                         else
                           ''
                         end

        # CRT serial
        crt = File.join(crt_dir, "#{base_filename}.crt")
        ret[dn]['crt_serial'] = get_cert_serial(crt)

        ca = File.join(crt_dir, "#{base_filename}_ca.pem")

        # DH
        dh = File.join(crt_dir, "#{base_filename}.dh")

        ret[dn]['ready_for_merge'] = File.exist?(csr) &&
                                     File.exist?(crt) &&
                                     File.exist?(dh) &&
                                     File.exist?(ca)
      end
      ret
    else
      {}
    end
  end
end
