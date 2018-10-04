#!/usr/bin/ruby

require 'json'
require 'open3'
require 'uri'
require 'optparse'

DEHYDRATED = nil

def run_dehydrated(dehydrated_config, command)
  unless DEHYDRATED && File.exist?(DEHYDRATED)
    raise 'dehydrated script not found or missing in config'
  end
  cmd = "#{DEHYDRATED} --dehydrated_config '#{dehydrated_config}' #{command}"
  stdout, stderr, status = Open3.capture3(cmd)

  [stdout, stderr, status.success?]
end

def _get_authority_url(crt, url_description)
  authority_info_access = crt.extensions.find do |extension|
    extension.oid == 'authorityInfoAccess'
  end

  descriptions = authority_info_access.value.split "\n"
  url_description = descriptions.find do |description|
    description.start_with? url_description
  end
  URI url_description[%r{URI:(.*)}, 1]
end

def update_ca_chain(crt_file, ca_file)
  raw_crt = File.read(crt_file)
  crt = OpenSSL::X509::Certificate.new(raw_crt)
  ca_issuer_uri = _get_authority_url(crt, 'CA Issuers')
  limit = 10
  ca_crt = ''
  while limit > 0
    response = Net::HTTP.get_response(ca_issuer_uri)
    case response
    when Net::HTTPSuccess then
      ca_crt = response.body
      status = 0
      stdout = ca_cert
      stderr = response.message
    when Net::HTTPRedirection then
      ca_issuer_uri = URI(response['location'])
      limit -= 1
      status = response.status
      stdout = response.body
      stderr = response.message
      next
    else
      status = response.status
      stdout = ''
      stderr = response.message
    end
    break
  end
  if status.zero? && ca_crt =~ %r{.*-+BEGIN CERTIFICATE-+.*-+END CERTIFICATE-+.*}m
    File.write(ca_file, ca_crt)
  end
  [stdout, stderr, status]
end

def update_ocsp(ocsp_file, crt_file, ca_file)
  crt = OpenSSL::X509::Certificate.new(File.read(crt_file))
  ca = OpenSSL::X509::Certificate.new(File.read(ca_file))
  digest = OpenSSL::Digest::SHA1.new
  certificate_id = OpenSSL::OCSP::CertificateId.new(crt, ca, digest)
  request = OpenSSL::OCSP::Request.new
  request.add_certid certificate_id

  # seems LE doesn't handle nonces.
  # request.add_nonce

  ocsp_uri = _get_authority_url(crt, 'OCSP')

  ocsp_response = ''
  while limit > 0
    response = Net::HTTP.start ocsp_uri.hostname, ocsp_uri.port do |http|
      http.post(
        ocsp_uri.path,
        request.to_der,
        'content-type' => 'application/ocsp-request',
      )
    end
    case response
    when Net::HTTPSuccess then
      ocsp_response = response.body
      status = 0
      stdout = ''
      stderr = response.message
    when Net::HTTPRedirection then
      ocsp_uri = URI(response['location'])
      limit -= 1
      status = response.status
      stdout = response.body
      stderr = response.message
      next
    else
      status = response.status
      stdout = ''
      stderr = response.message
    end
    break
  end

  if status.zero? && ocsp_response != ''
    ocsp = OpenSSL::OCSP::Response.new ocsp_response
    store = OpenSSL::X509::Store.new
    store.set_default_paths

    if ocsp.verify([], store)
      File.write(ocsp_file, ocsp.to_der)
    else
      status = 1
      stderr = stdout = 'OCSP verification failed'
    end
  end
  [status, stdout, stderr]
end

def register_account(dehydrated_config)
  run_dehydrated(env, dehydrated_config, '--accept-terms --register')
end

def update_account(dehydrated_config)
  run_dehydrated(env, dehydrated_config, '--account')
end

def sign_csr(dehydrated_config, csr_file, crt_file)
  stdout, stderr, status = run_dehydrated(env, dehydrated_config, "--signcsr '#{csr_file}'")
  if status.zero?
    if stdout =~ %r{.*-+BEGIN CERTIFICATE-+.*-+END CERTIFICATE-+.*}m
      File.write(crt_file, stdout)
    else
      # this case should never happen
      stdout = "# -- is this a certificate?? -- \n #{stdout}"
      status = 255
    end
  end
  [stdout, stderr, status]
end

def cert_still_valid(crt_file)
  if File.exist?(crt_file)
    raw_crt = File.read(crt_file)
    crt = OpenSSL::X509::Certificate.new(raw_crt)
    min_valid = Time.now + (30 * 24 * 60 * 60)
    crt.not_after > min_valid
  else
    false
  end
end

def handle_request(fqdn, dn, config)
  # set environment from config
  env = config['dehydrated_environment']
  old_env = {}
  env.each do |key, value|
    old_env[key] = value
    ENV[key] = value
  end

  # set paths/filenames
  dehydrated_config = config['dehydrated_config']
  letsencrypt_ca_hash = config['letsencrypt_ca_hash']
  request_fqdn_dir = config['request_fqdn_dir']
  request_base_dir = config['request_base_dir']
  base_filename = config['base_filename']
  crt_file = File.join(request_base_dir, "#{base_filename}.crt")
  csr_file = File.join(request_base_dir, "#{base_filename}.csr")
  ca_file = File.join(request_base_dir, "#{base_filename}_ca.pem")
  ocsp_file = "#{crt_file}.ocsp"

  # register / update account
  account_json = File.join(request_fqdn_dir, 'accounts', letsencrypt_ca_hash, 'registration_info.json')
  if !File.exist?(account_json)
    stdout, stderr, status = register_account(dehydrated_config)
    return ['Account registration failed', stdout, stderr, status] if status > 0
  else
    registration_info = JSON.parse(File.read(account_json))
    if registration_info['contact'].any?
      current_contact = registration_info['contact'][0]
      current_contact.gsub!(%r{^mailto:}, '')
    else
      current_contact = ''
    end
    required_contact = config['dehydrated_contact_email']
    if current_contact != required_contact
      stdout, stderr, status = update_account(dehydrated_config)
      return ['Account update failed', stdout, stderr, status] if status > 0
    end
  end


  unless cert_still_valid(crt_file)
    stdout, stderr, status = sign_csr(dehydrated_config, csr_file, crt_file)
    return ['CSR signing failed', stdout, stderr, status] if status > 0
  end

  if cert_still_valid(crt_file) && !cert_still_valid(ca_file)
    stdout, stderr, status = update_ca_chain(crt_file, ca_file)
    return ['CA certificate update failed', stdout, stderr, status] if status > 0
  end

  if cert_still_valid(crt_file) && cert_still_valid(ca_file)
    unless File.exist?(ocsp_file) && (File.mtime(ocsp_file) + 24 * 60 * 60) > Time.now
      stdout, stderr, status = update_ocsp(ocsp_file, crt_file, ca_file)
      return ['OCSP update failed', stdout, stderr, status] if status > 0
    end
  end
  old_env.each do |key, value|
    ENV[key] = value
  end

  [
    'CRT/CA/OCSP uptodate',
    "(#{dn} for #{fqdn})",
    '',
    0,
  ]
end

#{
#  "fuzz.foobar.com": {
#    "s.foobar.com": {
#      "subject_alternative_names": [
#
#      ],
#      "base_filename": "s.foobar.com",
#      "crt_serial": "265388138389643886446771048440882966446123",
#      "request_fqdn_dir": "/opt/dehydrated/requests/fuzz.foobar.com",
#      "request_base_dir": "/opt/dehydrated/requests/fuzz.foobar.com/s.foobar.com",
#      "dehydrated_environment": {
#      },
#      "dehydrated_hook": "dns-01.sh",
#      "dehydrated_domain_validation_hook": null,
#      "dehydrated_contact_email": "",
#      "letsencrypt_ca_url": "https://acme-staging-v02.api.letsencrypt.org/directory",
#      "letsencrypt_ca_hash": "aHR0cHM6Ly9hY21lLXN0YWdpbmctdjAyLmFwaS5sZXRzZW5jcnlwdC5vcmcvZGlyZWN0b3J5Cg",
#      "dehydrrated_config": "/opt/dehydrated/requests/fuzz.foobar.com/s.foobar.com/s.foobar.com.config"
#    },
#    "tt.foobar.com": {
#      "subject_alternative_names": [
#
#      ],
#      "base_filename": "tt.foobar.com",
#      "crt_serial": "",
#      "request_fqdn_dir": "/opt/dehydrated/requests/fuzz.foobar.com",
#      "request_base_dir": "/opt/dehydrated/requests/fuzz.foobar.com/tt.foobar.com",
#      "dehydrated_environment": {
#      },
#      "dehydrated_hook": "dns-01.sh",
#      "dehydrated_domain_validation_hook": null,
#      "dehydrated_contact_email": "",
#      "letsencrypt_ca_url": "https://acme-staging-v02.api.letsencrypt.org/directory",
#      "letsencrypt_ca_hash": "aHR0cHM6Ly9hY21lLXN0YWdpbmctdjAyLmFwaS5sZXRzZW5jcnlwdC5vcmcvZGlyZWN0b3J5Cg",
#      "dehydrrated_config": "/opt/dehydrated/requests/fuzz.foobar.com/tt.foobar.com/tt.foobar.com.config"
#    }
#  }
#}
#
#{"base_dir":"/etc/dehydrated","crt_dir":"/etc/dehydrated/certs","csr_dir":"/etc/dehydrated/csr","dehydrated_base_dir":"/opt/dehydrated","dehydrated_host":"fuzz.foobar.com","dehydrated_puppetmaster":"puppet.foobar.com","dehydrated_requests_dir":"/opt/dehydrated/requests","dehydrated_requests_config":"/opt/dehydrated/requests.json","key_dir":"/etc/dehydrated/private"}


# dehydrated@fuzz:~/dehydrated$ ./dehydrated  --config /opt/dehydrated/requests/fuzz.foobar.com/tt.foobar.com/tt.foobar.com.config --accept-terms --register 
# # INFO: Using main config file /opt/dehydrated/requests/fuzz.foobar.com/tt.foobar.com/tt.foobar.com.config
# + Generating account key...
# + Registering account key with ACME server...
# + Done!
# dehydrated@fuzz:~/dehydrated$ ./dehydrated  --config /opt/dehydrated/requests/fuzz.foobar.com/tt.foobar.com/tt.foobar.com.config --account
# # INFO: Using main config file /opt/dehydrated/requests/fuzz.foobar.com/tt.foobar.com/tt.foobar.com.config
# + Updating registration id: 7051511 contact information...
# + Backup /opt/dehydrated/requests/fuzz.foobar.com/accounts/aHR0cHM6Ly9hY21lLXN0YWdpbmctdjAyLmFwaS5sZXRzZW5jcnlwdC5vcmcvZGlyZWN0b3J5Cg/registration_info.json as /opt/dehydrated/requests/fuzz.foobar.com/accounts/aHR0cHM6Ly9hY21lLXN0YWdpbmctdjAyLmFwaS5sZXRzZW5jcnlwdC5vcmcvZGlyZWN0b3J5Cg/registration_info-1538498361.json
# + Populate /opt/dehydrated/requests/fuzz.foobar.com/accounts/aHR0cHM6Ly9hY21lLXN0YWdpbmctdjAyLmFwaS5sZXRzZW5jcnlwdC5vcmcvZGlyZWN0b3J5Cg/registration_info.json
# + Done!
# dehydrated@fuzz:~/dehydrated$ cat /opt/dehydrated/requests/fuzz.foobar.com/accounts/aHR0cHM6Ly9hY21lLXN0YWdpbmctdjAyLmFwaS5sZXRzZW5jcnlwdC5vcmcvZGlyZWN0b3J5Cg/registration_info.json
# {
#   "id": 7051511,
#   "key": {
#     "kty": "RSA",
#     "n": "zNF9NidRA9VLRfUtDFcK4xnFOXmR-rWA-O76XHGlbDLcBJYkA513GTVcnfZ1la_nK4qIrkH2WDIFX0wMyym9o_YTqbSa966vhhQM4d-S9qMP1aoInbEqLvePi5t-ZbxfPG6PsrgEcDirtP_BvmYhhCF0Q871cqaG2h8ZCkfl7MIRJGOVKpM8_AwcP7VBdoXRF-twNBzKdwRksGODmKJ-69KLZ6X-l1XUwN77p_1-YpJdsodNlwGrm_4NpJP_hySnTq3bunhZZYLwBogcswKEgj2m2-fYuhRWeGv4cLmRyPC8huF5nJUwsUyTB2bCqyIJJzpnWn3O-d8818Q64377Bk4hMhc9xHC4xSRTxFbNYK0aLlBz6-SMLcxXpbyzl7zsoWN12kdSt9ZIN-dPNH01KucE3Y0xzUm7D8Fxu6NfizQEDQq7a4er0WQnxfuVFYauwpVzreO_g3Ba-KKpcz32rWD9Bk68TQPuOJdlLlUev6EVsTueL3Ywbkm66p3QsrAdcsfFKDtzjYLl-D2PYNrxgNLravZxN0Q4I03NRuZeEeMx7t77TTcATmLsDazLYdOeWKyYnL0D6N-POg17t2S0ms76RVokiyPjbWXa7LJgmXK46EnqVvFE5yOhJQLnoJrRv3TQAoFUYiTtlAtI7oodzNqQf_bVAVf7FZa1ZjRYuss",
#     "e": "AQAB"
#   },
#   "contact": [],
#   "initialIp": "2a02:16a8:dc4:a01::211",
#   "createdAt": "2018-10-02T16:39:08Z",
#   "status": "valid"
# }dehydrated@fuzz:~/dehydrated$ 
# dehydrated@fuzz:~/dehydrated$ vim /opt/dehydrated/requests/fuzz.foobar.com/tt.foobar.com/tt.foobar.com.config
# dehydrated@fuzz:~/dehydrated$ ./dehydrated  --config /opt/dehydrated/requests/fuzz.foobar.com/tt.foobar.com/tt.foobar.com.config --account
# # INFO: Using main config file /opt/dehydrated/requests/fuzz.foobar.com/tt.foobar.com/tt.foobar.com.config
# + Updating registration id: 7051511 contact information...
# + Backup /opt/dehydrated/requests/fuzz.foobar.com/accounts/aHR0cHM6Ly9hY21lLXN0YWdpbmctdjAyLmFwaS5sZXRzZW5jcnlwdC5vcmcvZGlyZWN0b3J5Cg/registration_info.json as /opt/dehydrated/requests/fuzz.foobar.com/accounts/aHR0cHM6Ly9hY21lLXN0YWdpbmctdjAyLmFwaS5sZXRzZW5jcnlwdC5vcmcvZGlyZWN0b3J5Cg/registration_info-1538498472.json
# + Populate /opt/dehydrated/requests/fuzz.foobar.com/accounts/aHR0cHM6Ly9hY21lLXN0YWdpbmctdjAyLmFwaS5sZXRzZW5jcnlwdC5vcmcvZGlyZWN0b3J5Cg/registration_info.json
# + Done!
# dehydrated@fuzz:~/dehydrated$ cat /opt/dehydrated/requests/fuzz.foobar.com/accounts/aHR0cHM6Ly9hY21lLXN0YWdpbmctdjAyLmFwaS5sZXRzZW5jcnlwdC5vcmcvZGlyZWN0b3J5Cg/registration_info.json
# {
#   "id": 7051511,
#   "key": {
#     "kty": "RSA",
#     "n": "zNF9NidRA9VLRfUtDFcK4xnFOXmR-rWA-O76XHGlbDLcBJYkA513GTVcnfZ1la_nK4qIrkH2WDIFX0wMyym9o_YTqbSa966vhhQM4d-S9qMP1aoInbEqLvePi5t-ZbxfPG6PsrgEcDirtP_BvmYhhCF0Q871cqaG2h8ZCkfl7MIRJGOVKpM8_AwcP7VBdoXRF-twNBzKdwRksGODmKJ-69KLZ6X-l1XUwN77p_1-YpJdsodNlwGrm_4NpJP_hySnTq3bunhZZYLwBogcswKEgj2m2-fYuhRWeGv4cLmRyPC8huF5nJUwsUyTB2bCqyIJJzpnWn3O-d8818Q64377Bk4hMhc9xHC4xSRTxFbNYK0aLlBz6-SMLcxXpbyzl7zsoWN12kdSt9ZIN-dPNH01KucE3Y0xzUm7D8Fxu6NfizQEDQq7a4er0WQnxfuVFYauwpVzreO_g3Ba-KKpcz32rWD9Bk68TQPuOJdlLlUev6EVsTueL3Ywbkm66p3QsrAdcsfFKDtzjYLl-D2PYNrxgNLravZxN0Q4I03NRuZeEeMx7t77TTcATmLsDazLYdOeWKyYnL0D6N-POg17t2S0ms76RVokiyPjbWXa7LJgmXK46EnqVvFE5yOhJQLnoJrRv3TQAoFUYiTtlAtI7oodzNqQf_bVAVf7FZa1ZjRYuss",
#     "e": "AQAB"
#   },
#   "contact": [
#     "mailto:test@foobar.com"
#   ],
#   "initialIp": "2a02:16a8:dc4:a01::211",
#   "createdAt": "2018-10-02T16:39:08Z",
#   "status": "valid"
# }dehydrated@fuzz:~/dehydrated$ 
# 
