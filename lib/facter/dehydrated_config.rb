require 'facter'
require 'json'
require 'openssl'

puppet_vardir = Facter.value(:puppet_vardir)
configfile = File.join(puppet_vardir, 'config.json')

config = if File.exist?(configfile)
           JSON.parse(File.read(configfile))
         else
           nil
         end

Facter.add(:dehydrated_config) do
  setcode do
    config
  end
end

def get_cert_serial(crt)
  unless File.exist?(crt)
    return -1
  end

  raw_cert = File.read(crt)
  begin
    cert = OpenSSL::X509::Certificate.new raw_cert
    return cert.serial.to_i
  rescue OpenSSL::X509::CertificateError
    return -1
  end
end

Facter.add(:dehydrated_domains) do
  setcode do
    puppet_vardir = Facter.value(:puppet_vardir)
    domainsfile = File.join(puppet_vardir, 'domains.json')
    if File.exist?(domainsfile)
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

        # DH mtimes
        dh = File.join(crt_dir, "#{base_filename}.dh")
        if File.exist?(dh) && File.size?(dh)
          mtime = File.mtime(dh).to_i
          ret[dn]['dh_mtime'] = mtime
        else
          ret[dn]['dh_mtime'] = -999_999_999
        end
      end
      ret
    else
      {}
    end
  end
end
