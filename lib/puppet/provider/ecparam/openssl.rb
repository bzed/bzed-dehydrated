require 'pathname'
require 'openssl'
Puppet::Type.type(:ecparam).provide(:openssl) do
  desc 'Manages ec params with OpenSSL'

  def self.dirname(resource)
    resource[:path].dirname
  end

  def self.generate_key(resource)
    OpenSSL::PKey::EC.generate(resource[:short_name])
  end

  def self.to_pem(resource, key)
    if resource[:password]
      cipher = OpenSSL::Cipher.new('aes256')
      key.to_pem(cipher, resource[:password])
    else
      key.to_pem
    end
  end

  def exists?
    Pathname.new(resource[:path]).exist?
  end

  def create
    key = self.class.generate_key(resource)
    pem = self.class.to_pem(resource, key)
    File.open(resource[:path], 'w') do |f|
      f.write(pem)
    end
  end

  def destroy
    Pathname.new(resource[:path]).delete
  end
end
