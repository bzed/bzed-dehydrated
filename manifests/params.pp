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
      $user = $::identity['user']
      $group = undef
      $base_dir = 'C:\\LE_certs'
      $path_seperator = '\\'
      $manage_user = false
      $configfile = ''
    }
    'Linux' : {
      $user = 'dehydrated'
      $group = 'dehydrated'
      $path_seperator = '/'
      case $::os['family'] {
        'Debian' : {
          $pki_packages = ['pki-base']
        }
        default: {}
      }
      $base_dir = '/etc/pki/dehydrated'
      $manage_user = true
    }
    default : { fail('Your OS is not supported!')}
  }

  $csr_dir = join($base_dir, 'csr', $path_seperator)
  $crt_dir = join($base_dir, 'certs', $path_seperator)
  $key_dir = join($base_dir, 'private', $path_seperator)

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

  #ssl settings
  $dh_param_size = 2048

}

