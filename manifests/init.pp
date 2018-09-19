# Base class to setup the letsencrypt certificate handling
# with dehydrated.
#
# @summary Base class to define necessary variables and include setup classes.
#
# @example
#   include dehydrated
#
# @api public

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

  String $letsencrypt_ca = $::dehydrated::params::letsencrypt_ca,
  Hash $letsencrypt_cas = $::dehydrated::params::letsencrypt_cas,
  Integer $dh_param_size = $::dehydrated::params::dh_param_size,
  Dehydrated::Challengetype $challengetype = $::dehydrated::params::challengetype,

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
  Optional[Array[Variant[Dehydrated::DN, Tuple[Dehydrated::DN, Array[Dehydrated::DN]]]]] $certificates = undef,

) inherits ::dehydrated::params {

  require ::dehydrated::setup

  if ($dehydrated_host == $facts['fqdn']) {
    require ::dehydrated::setup::dehydrated_host
  }

}
