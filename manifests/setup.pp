# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include dehydrated::setup
class dehydrated::setup {

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
  
}

