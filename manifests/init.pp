# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include dehydrated
class dehydrated
(
  Stdlib::Absolutepath $base_dir = $::dehydrated::params::base_dir,
  Stdlib::Absolutepath $crt_dir = $::dehydrated::params::crt_dir,
  Stdlib::Absolutepath $csr_dir = $::dehydrated::params::csr_dir,
  Stdlib::Absolutepath $key_dir = $::dehydrated::params::key_dir,
  String $user = $::dehydrated::params::user,
  Optional[String] $group = $::dehydrated::params::group,
  Optional[String] $dehydrated_user = $::dehydrated::params::dehydrated_user,
  Optional[String] $dehydrated_group = $::dehydrated::params::dehydrated_group,

  Integer $dh_param_size = $::dehydrated::params::dh_param_size,
  String $letsencrypt_ca = $::dehydrated::params::letsencrypt_ca,
  Hash $letsencrypt_cas = $::dehydrated::params::letsencrypt_cas,

  Stdlib::Absolutepath $configdir = $::dehydrated::params::configdir,
  Stdlib::Absolutepath $configfile = $::dehydrated::params::configfile,

  Stdlib::Absolutepath $dehydrated_base_dir = $::dehydrated::params::dehydrated_base_dir,
  Stdlib::Absolutepath $dehydrated_git_dir = $::dehydrated::params::dehydrated_git_dir,
  String $dehydrated_git_tag = $::dehydrated::params::dehydrated_git_tag,
  Dehydrated::GitUrl $dehydrated_git_url = $::dehydrated::params::dehydrated_git_url,
  Stdlib::Fqdn $dehydrated_host = $::dehydrated::params::dehydrated_host,
  Stdlib::Absolutepath $dehydrated_requests_dir = $::dehydrated::params::dehydrated_requests_dir,
  Stdlib::Absolutepath $dehydrated_wellknown_dir = $::dehydrated::params::dehydrated_wellknown_dir,

  Boolean $manage_user = $::dehydrated::params::manage_user,
  Boolean $manage_packages = $::dehydrated::params::manage_packages,

  Array $pki_packages = $::dehydrated::params::pki_packages,
  Array $packages = $::dehydrated::params::packages,

) inherits ::dehydrated::params {

  require ::dehydrated::setup

  if ($dehydrated_host == $facts['fqdn']) {
    require ::dehydrated::setup::dehydrated_host
  }

}
