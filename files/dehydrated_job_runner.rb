#!/usr/bin/ruby

require 'json'
require 'open3'

def run_dehydrated(env, config, command)
    old_env = {}
    env.each do |key, value|
        old_env[key] = value
        ENV[key] = value
    end

    cmd = "#{DEHYDRATED} --config '#{config}' #{command}"
    stdout, stderr, status = Open3.capture3(cmd)

    old_env.each do |key, value|
        ENV[key] = value
    end
    [stdout, stderr, status.success?]
end

def register_account(env, config)
    run_dehydrated(env, config, '--accept-terms --register')
end

def update_account(env, config)
    run_dehydrated(env, config, '--account')
end

def sign_csr(env, config, csr)
    run_dehydrated(env, config, "--signcsr '#{csr}'")
end

DEHYDRATED="/opt/dehydrated/dehydrated/dehydrated"

a=sign_csr({}, '/tmp/foo', '/tmp/bar')
p a[0]
p a[1]
p a[2]


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
#      "config_file": "/opt/dehydrated/requests/fuzz.foobar.com/s.foobar.com/s.foobar.com.config"
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
#      "config_file": "/opt/dehydrated/requests/fuzz.foobar.com/tt.foobar.com/tt.foobar.com.config"
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
