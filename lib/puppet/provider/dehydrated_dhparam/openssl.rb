# frozen_string_literal: true

# idea taken from https://github.com/camptocamp/puppet-openssl/blob/master/lib/puppet/provider/dhparam/openssl.rb
# Apache License, Version 2.0, January 2004

require 'pathname'
Puppet::Type.type(:dehydrated_dhparam).provide(:openssl) do
  desc 'Manages dhparam files with OpenSSL'

  commands openssl: 'openssl'

  def exists?
    key_ok = if resource[:size] < 2048
               # replace dhparms regularily to avoid logjam attacks
               # should not be necessary with dhparams >= 2048.
               # please send pull requests if my knowledge is wrong :)
               Pathname.new(resource[:path]).exist? && (File.mtime(resource[:path]) + (24 * 60 * 60)) > Time.now
             else
               Pathname.new(resource[:path]).exist?
             end

    if key_ok
      content = File.read(resource[:path])
      if content.empty?
        false
      else
        begin
          dh = OpenSSL::PKey::DH.new(content)
          dh.params_ok?
        rescue OpenSSL::PKey::DHError
          false
        end
      end
    else
      false
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
