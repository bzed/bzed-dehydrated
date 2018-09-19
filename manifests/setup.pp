# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include dehydrated::setup
class dehydrated::setup {

  require ::dehydrated::params

  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first; also this class is not supposed to be included on its own.')
  }

  if ($::dehydrated::manage_user) {
    if ($facts['kernel'] == 'windows') {
      fail('User management not configured for windows')
    }
  }


  if (($facts['kernel'] != 'windows') and (!empty($::dehydrated::pki_packages))) {
    ensure_packages($::dehydrated::pki_packages)
  }

  if ($::dehydrated::manage_packages) {
    ensure_packages($::dehydrated::packages)
  }

  $config = {
    'base_dir' => $::dehydrated::base_dir,
    'crt_dir' => $::dehydrated::crt_dir,
    'csr_dir' => $::dehydrated::csr_dir,
    'dehydrated_base_dir' => $::dehydrated::dehydrated_base_dir,
    'dehydrated_requests_dir' => $::dehydrated::dehydrated_requests_dir,
    'key_dir' => $::dehydrated::key_dir,
    'letsencrypt_ca_url' => $::dehydrated::letsencrypt_cas[$::dehydrated::letsencrypt_ca]['url'],
    'letsencrypt_ca_hash' => $::dehydrated::letsencrypt_cas[$::dehydrated::letsencrypt_ca]['hash'],
  }

  File {
    owner => $::dehydrated::params::puppet_user,
    group => $::dehydrated::params::puppet_group,
  }

  file { $::dehydrated::params::configdir :
    ensure => directory,
    mode   => '0750',
  }

  file { $::dehydrated::params::configfile :
    ensure  => file,
    mode    => '0640',
    content => to_json($config),
  }
}

