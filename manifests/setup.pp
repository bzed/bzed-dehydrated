# This class creates all the necessary files and folders
# do handle key/csr creation and crt storage.
# It shoudld never be included in your puppet code.
#
# @summary Setup required files and folders. Don't include/call this class.
#
# @api private
#
class dehydrated::setup {

  require ::dehydrated::params

  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first; also this class is not supposed to be included on its own.')
  }

  if ($::dehydrated::manage_user) {
    if ($facts['kernel'] == 'windows') {
      fail('User management not configured for windows')
    }

    if (defined('$::dehydrated::group')) {
      if ($::dehydrated::params::puppet_group != $::dehydrated::group) {
        group { $::dehydrated::group :
          ensure => 'present'
        }
        $group_require = Group[$::dehydrated::group]
      }
    }
  }
  if (! defined('$group_require')) {
    $group_require = undef
  }



  if ($::dehydrated::manage_packages) {
    ensure_packages($::dehydrated::packages)
    if (!empty($::dehydrated::pki_packages)) {
      ensure_packages($::dehydrated::pki_packages)
    }
  }

  $config = {
    'base_dir' => $::dehydrated::base_dir,
    'crt_dir' => $::dehydrated::crt_dir,
    'csr_dir' => $::dehydrated::csr_dir,
    'dehydrated_base_dir' => $::dehydrated::dehydrated_base_dir,
    'dehydrated_host' => $::dehydrated::dehydrated_host,
    'dehydrated_requests_dir' => $::dehydrated::dehydrated_requests_dir,
    'key_dir' => $::dehydrated::key_dir,
    'letsencrypt_ca_url' => $::dehydrated::letsencrypt_cas[$::dehydrated::letsencrypt_ca]['url'],
    'letsencrypt_ca_hash' => $::dehydrated::letsencrypt_cas[$::dehydrated::letsencrypt_ca]['hash'],
  }

  $config_json = to_json($config)

  file { $::dehydrated::params::configdir :
    ensure => directory,
    owner  => $::dehydrated::params::puppet_user,
    group  => $::dehydrated::params::puppet_group,
    mode   => '0750',
  }

  file { $::dehydrated::params::configfile :
    ensure  => file,
    owner   => $::dehydrated::params::puppet_user,
    group   => $::dehydrated::params::puppet_group,
    mode    => '0640',
    content => $config_json,
  }

  File {
    ensure  => directory,
    owner   => $::dehydrated::user,
    group   => $::dehydrated::group,
    mode    => '0755',
    require => $group_require,
  }

  file { [
    $::dehydrated::base_dir,
    $::dehydrated::crt_dir,
    $::dehydrated::csr_dir,
    ] :
  }

  file { $::dehydrated::key_dir :
    mode => '0750',
  }

  concat { $::dehydrated::params::domainfile :
    ensure => present
  }
}

