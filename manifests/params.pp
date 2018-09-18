# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include dehydrated::params
class dehydrated::params {

  # OS settings
  case $::kernel {
    'windows' : {
      $user = $facts['identity']['user']
      $group = undef
      $base_dir = 'C:\\LE_certs'
      $path_seperator = '\\'
      $manage_user = false
      fail($::settings::vardir)
      $puppet_vardir = regsubst($::settings::vardir, '/', '\\', 'G')
      $packages = []
      $manage_packages = false
      $dehydrated_user = undef
      $dehydrated_group = undef
      $pki_packages = []
    }
    'Linux' : {
      $user = $facts['user']
      case $user {
        'root' : {
          $group = 'dehydrated'
          $dehydrated_user = 'dehydrated'
          $manage_user = true
        }
        default : {
          $group = $facts['group']
          $dehydrated_user = $user
          $manage_user = false
        }
      }
      $dehydrated_group = $group
      $path_seperator = '/'
      case $::os['family'] {
        'Debian' : {
          $pki_packages = ['pki-base']
        }
        default: {
          $pki_packages = []
        }
      }
      $base_dir = '/etc/pki/dehydrated'
      $puppet_vardir = $::settings::vardir
      $packages = ['git', 'openssl']
      $manage_packages = true
    }
    default : { fail('Your OS is not supported!')}
  }

  $csr_dir = join([$base_dir, 'csr'], $path_seperator)
  $crt_dir = join([$base_dir, 'certs'], $path_seperator)
  $key_dir = join([$base_dir, 'private'], $path_seperator)

  $configdir = join([$puppet_vardir, 'bzed-dehydrated'], $path_seperator)
  $configfile = join([$configdir, 'config.json'], $path_seperator)

  # letsencrypt settings
  $letsencrypt_ca = 'v2-staging'
  $letsencrypt_cas = {
    'production' => {
      'url'  => 'https://acme-v01.api.letsencrypt.org/directory',
      'hash' => 'aHR0cHM6Ly9hY21lLXYwMS5hcGkubGV0c2VuY3J5cHQub3JnL2RpcmVjdG9yeQo'
    },
    'staging'    => {
      'url'  => 'https://acme-staging.api.letsencrypt.org/directory',
      'hash' => 'aHR0cHM6Ly9hY21lLXN0YWdpbmcuYXBpLmxldHNlbmNyeXB0Lm9yZy9kaXJlY3RvcnkK'
    },
    'v2-production' => {
      'url'  => 'https://acme-v02.api.letsencrypt.org/directory',
      'hash' => 'aHR0cHM6Ly9hY21lLXYwMi5hcGkubGV0c2VuY3J5cHQub3JnL2RpcmVjdG9yeQo'
    },
    'v2-staging'    => {
      'url'  => 'https://acme-staging-v02.api.letsencrypt.org/directory',
      'hash' => 'aHR0cHM6Ly9hY21lLXN0YWdpbmctdjAyLmFwaS5sZXRzZW5jcnlwdC5vcmcvZGlyZWN0b3J5Cg'
    },
  }

  # dehydrated setting
  $dehydrated_git_url = 'https://github.com/lukas2511/dehydrated.git'
  $dehydrated_git_tag = 'v0.6.2'

  $dehydrated_base_dir = '/opt/dehydrated'
  $dehydrated_requests_dir = "${dehydrated_base_dir}/requests"
  $dehydrated_git_dir = "${dehydrated_base_dir}/dehydrated"
  $dehydrated_wellknown_dir = "${dehydrated_base_dir}/.acme-challenges"

  if defined('$::puppetmaster') {
    $dehydrated_host = $::puppetmaster
  } elsif defined('$::servername') {
    $dehydrated_host = $::servername
  } else {
    $dehydrated_host = undef
  }

  #ssl settings
  $dh_param_size = 2048

}

