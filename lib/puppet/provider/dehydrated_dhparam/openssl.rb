# idea taken from https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/provider/dhparam/openssl.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
Puppet::Type.type(:dehydrated_dhparam).provide(:openssl) do
  desc 'Manages dhparam files with OpenSSL'

  commands :openssl => 'openssl'

  def exists?
    if resource[:size] < 2048
      # replace dhparms regularily to avoid logjam attacks
      # should not be necessary with dhparams >= 2048.
      # please send pull requests if my knowledge is wrong :)
      Pathname.new(resource[:path]).exist? && (File.mtime(resource[:path]) + 24 * 60 * 60) < Time.now
    else
      Pathname.new(resource[:path]).exist?
    end

  end

  def create
    dh = OpenSSL::PKey::DH.new(resource[:size])
    File.write(resource[:path], dh.to_pem)
  end

  def destroy
    Pathname.new(resource[:path]).delete
  end
end
