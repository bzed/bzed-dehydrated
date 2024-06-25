#!/usr/bin/env ruby

require 'json'
require 'open3'
require 'uri'
require 'openssl'
require 'net/http'
require 'shellwords'
require 'fileutils'

def run_domain_validation_hook(hook, dn, subject_alternative_names = [])
  if hook && File.exist?(hook) && File.executable?(hook)
    domains = [dn] + subject_alternative_names
    escaped_domains = domains.each do |domain|
      Shellwords.escape(domain)
    end
    args = escaped_domains.join(' ')
    cmd = "#{hook} #{args}"
    stdout, stderr, status = Open3.capture3(cmd)
    status = status.to_i >> 8
  else
    stdout = stderr = 'domain validation hook not found or not executable'
    status = 255
  end
  [stdout, stderr, status]
end

def run_dehydrated(dehydrated_config, command)
  unless DEHYDRATED && File.exist?(DEHYDRATED) && File.executable?(DEHYDRATED)
    raise 'dehydrated script not found or missing in config'
  end
  cmd = "#{DEHYDRATED} --config '#{dehydrated_config}' #{command}"
  stdout, stderr, status = Open3.capture3(cmd)

  [stdout, stderr, status.to_i >> 8]
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
      ca_crt_raw = response.body
      status = 0
      stdout = ca_crt
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
  if status.zero?
    ca_crt = OpenSSL::X509::Certificate.new(ca_crt_raw)
    File.write(ca_file, ca_crt.to_pem)
    File.write(ca_file + '.url', ca_issuer_uri.to_s)
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
  limit = 10
  while limit > 0
    path = if ocsp_uri.path.empty?
             '/'
           else
             ocsp_uri.path
           end
    response = Net::HTTP.start ocsp_uri.hostname, ocsp_uri.port do |http|
      http.post(
        path,
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
    store.add_cert(ca)

    if ocsp.basic # && ocsp.basic().verify([], store)
      File.write(ocsp_file, ocsp.to_der)
    else
      status = 1
      stderr = stdout = 'OCSP verification failed'
    end
  end
  [stdout, stderr, status.to_i]
end

def register_account(dehydrated_config)
  run_dehydrated(dehydrated_config, '--accept-terms --register')
end

def update_account(dehydrated_config)
  run_dehydrated(dehydrated_config, '--account')
end

def sign_csr(dehydrated_config, csr_file, crt_file, ca_file)
  # tidy url files, not used anymore
  ca_url_file = ca_file + '.url'
  File.delete(ca_url_file) if File.exist?(ca_url_file)

  stdout, stderr, status = run_dehydrated(dehydrated_config, "--signcsr '#{csr_file}'")
  if status.zero?
    certs = stdout.split("\n\n")
    if certs.size < 2
      stdout = "# -- CA certificate missing? -- \n #{stdout}"
      status = 255
    else
      crt = certs[0].sub("# CERT #\n", '')
      ca_crt = certs[1..-1].join("\n\n") + "\n"
      begin
        crt = OpenSSL::X509::Certificate.new(crt)
        File.write(crt_file, crt.to_pem)
        OpenSSL::X509::Certificate.new(ca_crt)
        File.write(ca_file, ca_crt)
      rescue OpenSSL::X509::CertificateError
        stdout = "# -- is this a certificate?? -- \n #{stdout}"
        status = 255
      end
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
  dn_config_file = File.join(request_base_dir, "#{base_filename}.json")
  crt_file = File.join(request_base_dir, "#{base_filename}.crt")
  csr_file = File.join(request_base_dir, "#{base_filename}.csr")
  ca_file = File.join(request_base_dir, "#{base_filename}_ca.pem")
  ocsp_file = "#{crt_file}.ocsp"
  subject_alternative_names = config['subject_alternative_names'].sort.uniq
  dehydrated_domain_validation_hook_script = config['dehydrated_domain_validation_hook_script']
  dehydrated_hook_script = config['dehydrated_hook_script']

  new_dn_config = {
    'letsencrypt_ca_hash' => letsencrypt_ca_hash,
    'dn' => dn,
    'subject_alternative_names' => subject_alternative_names,
  }
  # read old dn config if it exists
  current_dn_config = if File.exist?(dn_config_file)
                        JSON.parse(File.read(dn_config_file))
                      else
                        new_dn_config
                      end
  # use >= to allow to add new things to the config hash
  force_update = !(if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('2.3')
                     new_dn_config >= current_dn_config
                   else
                     current_dn_config.reduce(true) do |uptodate, n|
                       c = n[0]
                       s = n[1]
                       uptodate && (new_dn_config[c] == s)
                     end
                   end
                  )

  # register / update account
  # prior to 2024-04, the config did not contain the request_account_dir.  Fall back to the
  # previous method if we don't have request_account_dir in the config (yet?).
  accounts_dir = config['request_account_dir'] || File.join(request_fqdn_dir, 'accounts')
  account_json = File.join(accounts_dir, letsencrypt_ca_hash, 'registration_info.json')
  if !File.exist?(account_json)
    stdout, stderr, status = register_account(dehydrated_config)
    return ['Account registration failed', stdout, stderr, status] if status > 0
  else
    registration_info = JSON.parse(File.read(account_json))
    if registration_info['contact'].nil? || registration_info['contact'].empty?
      current_contact = ''
    else
      current_contact = registration_info['contact'][0]
      current_contact.gsub!(%r{^mailto:}, '')
    end
    required_contact = config['dehydrated_contact_email']
    if current_contact != required_contact
      stdout, stderr, status = update_account(dehydrated_config)
      return ['Account update failed', stdout, stderr, status] if status > 0
    end
  end

  if !cert_still_valid(crt_file) || force_update || !cert_still_valid(ca_file)
    if dehydrated_domain_validation_hook_script && !dehydrated_domain_validation_hook_script.empty?
      stdout, stderr, status = run_domain_validation_hook(
        dehydrated_domain_validation_hook_script,
        dn,
        subject_alternative_names,
      )
      return ['Domain validation hook failed', stdout, stderr, status] if status > 0
    end

    unless dehydrated_hook_script.nil? || dehydrated_hook_script.empty?
      unless File.exist?(dehydrated_hook_script) && File.executable?(dehydrated_hook_script)
        return ['Configured Dehydrated hook does not exist or is not executable',
                dehydrated_hook_script,
                '',
                255]
      end
      # nothing else to do here, the hook is configured
      # in the dehydrated config file already.
    end

    stdout, stderr, status = sign_csr(dehydrated_config, csr_file, crt_file, ca_file)
    if status > 0 || !cert_still_valid(crt_file)
      return ['CSR signing failed', stdout, stderr, status] if status > 0
    end
    # remove ocsp file after getting a new certificate
    if status.zero? && File.exist?(ocsp_file)
      File.delete(ocsp_file)
    end
  end

  # track currently used config
  # we do this before the OCSP stuff as we have a valid cert already.
  File.write(dn_config_file, JSON.generate(new_dn_config))

  if cert_still_valid(crt_file)
    ocsp_uptodate = File.exist?(ocsp_file) &&
                    (File.mtime(ocsp_file) + 24 * 60 * 60) > Time.now &&
                    File.mtime(ocsp_file) > File.mtime(crt_file)
    unless ocsp_uptodate
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

def prepare_files(request_config)
  request_base_dir = request_config['request_base_dir']
  csr_file = request_config['csr_file']
  csr_content = request_config['csr_content']
  dehydrated_config = request_config['dehydrated_config']
  dehydrated_config_content = request_config['dehydrated_config_content']

  FileUtils.mkdir_p request_base_dir
  File.write(csr_file, csr_content)
  File.write(dehydrated_config, dehydrated_config_content)
end

def run_config(dehydrated_requests_config)
  requests_status = {}
  dehydrated_requests_config.each do |fqdn, dns|
    requests_status[fqdn] = {}
    dns.each do |dn, config|
      if config.key?('dehydrated_config_content')
        prepare_files(config)
      end
      error_message, stdout, stderr, statuscode = handle_request(fqdn, dn, config)
      requests_status[fqdn][dn] = {
        'error_message' => error_message,
        'stdout' => stdout,
        'stderr' => stderr,
        'statuscode' => statuscode,
      }
    end
  end
  requests_status
end

def write_status_file(requests_status, status_file, monitoring_status_file)
  File.write(status_file, JSON.pretty_generate(requests_status))

  errormsg = []
  ok_count = 0
  bad_count = 0
  requests_status.each do |fqdn, dns|
    dns.each do |dn, status|
      if status['statuscode'].to_i > 0
        bad_count += 1
        errormsg << "#{dn} (from #{fqdn}): #{status['error_message']}"
      else
        ok_count += 1
      end
    end
  end

  monitoring_status = if bad_count > 0
                        'CRITICAL'
                      else
                        'OK'
                      end
  output = [monitoring_status.to_s, "dehydrated certificates: OK: #{ok_count}, FAILED: #{bad_count}"]
  output += errormsg

  File.write(monitoring_status_file, output.join("\n"))
end

if ARGV.empty?
  raise ArgumentError, 'Need to specify config.json as argument'
end

dehydrated_host_config_file = ARGV[0]
dehydrated_host_config = JSON.parse(File.read(dehydrated_host_config_file))
dehydrated_requests_config_file = dehydrated_host_config['dehydrated_requests_config']
dehydrated_requests_config = JSON.parse(File.read(dehydrated_requests_config_file))
# dehydrated_base_dir = dehydrated_host_config['dehydrated_base_dir']
dehydrated_git_dir = dehydrated_host_config['dehydrated_git_dir']
dehydrated_status_file = dehydrated_host_config['dehydrated_status_file']
dehydrated_monitoring_status_file = dehydrated_host_config['dehydrated_monitoring_status_file']
DEHYDRATED = File.join(dehydrated_git_dir, 'dehydrated')

request_status = run_config(dehydrated_requests_config)
write_status_file(
  request_status,
  dehydrated_status_file,
  dehydrated_monitoring_status_file,
)

# rubocop:disable all
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
#      "dehydrated_hook_script": "dns-01.sh",
#      "dehydrated_domain_validation_hook_script": null,
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
#      "dehydrated_hook_script": "dns-01.sh",
#      "dehydrated_domain_validation_hook_script": null,
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
