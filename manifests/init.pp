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
  Integer[768] $dh_param_size = $::dehydrated::params::dh_param_size,
  Dehydrated::Challengetype $challengetype = $::dehydrated::params::challengetype,

  Stdlib::Absolutepath $dehydrated_base_dir = $::dehydrated::params::dehydrated_base_dir,
  Stdlib::Absolutepath $dehydrated_git_dir = $::dehydrated::params::dehydrated_git_dir,
  String $dehydrated_git_tag = $::dehydrated::params::dehydrated_git_tag,
  Dehydrated::GitUrl $dehydrated_git_url = $::dehydrated::params::dehydrated_git_url,
  Stdlib::Fqdn $dehydrated_host = $::dehydrated::params::dehydrated_host,
  Stdlib::Absolutepath $dehydrated_requests_dir = $::dehydrated::params::dehydrated_requests_dir,
  Stdlib::Absolutepath $dehydrated_requests_config = $::dehydrated::params::dehydrated_requests_config,
  Stdlib::Absolutepath $dehydrated_wellknown_dir = $::dehydrated::params::dehydrated_wellknown_dir,
  Array $dehydrated_host_packages = $::dehydrated::params::dehydrated_host_packages,

  Boolean $manage_user = $::dehydrated::params::manage_user,
  Boolean $manage_packages = $::dehydrated::params::manage_packages,

  Array $pki_packages = $::dehydrated::params::pki_packages,
  Array $packages = $::dehydrated::params::packages,
  Array[Variant[Dehydrated::DN, Tuple[Dehydrated::DN, Array[Dehydrated::DN]]]] $certificates = [],

) inherits ::dehydrated::params {

  require ::dehydrated::setup

  $certificates.each | $certificate | {
    if ($certificate =~ Tuple[Dehydrated::DN, Array[Dehydrated::DN]]) {
      ::dehydrated::certificate { $certificate[0] :
        subject_alternative_names => $certificate[1],
      }
    } else {
      ::dehydrated::certificate { $certificate : }
    }
  }

  $dehydrated_domains = $facts['dehydrated_domains']
  $dehydrated_domains.each |Dehydrated::DN $_dn, Hash $_config| {
    $_base_filename = $_config['base_filename']
    $_dh_param_size = $_config['dh_param_size']
    $_dh_mtime = $_config['dh_mtime']
    $_csr = $_config['csr']
    $_crt_serial = $_config['crt_serial']
    $_subject_alternative_names = $_config['subject_alternative_names']
    $_dehydrated_host = $_config['dehydrated_host']

    ::dehydrated::certificate::dh { $_base_filename :
      dn            => $_dn,
      dh_param_size => $_dh_param_size,
      dh_mtime      => $_dh_mtime,
    }

    $request_name = join(
      concat(
        [$facts['fqdn'], $_dn],
        $_subject_alternative_names
      ),
    '-')

    if $_csr =~ Dehydrated::CSR {
      @@dehydrated::certificate::request { $request_name :
        tag => "dehydrated-request-for-${_dehydrated_host}",
      }
    }

    Dehydrated::Certificate::Transfer<<|
      tag == "request_fqdn:${facts['fqdn']}" and
      tag == "request_dn:${_dn}"
    |>>

  }

  if ($dehydrated_host == $facts['fqdn']) {
    require ::dehydrated::setup::dehydrated_host

    Dehydrated::Certificate::Request<<| tag == "dehydrated-request-for-${dehydrated_host}" |>>

    if has_key($facts, 'dehydrated_certificates') {
      $dehydrated_certificates = $facts['dehydrated_certificates']
      $dehydrated_certificates.each |Stdlib::Fqdn $_request_fqdn, Hash $_certificate_configs| {
        $_certificate_configs.each |Dehydrated::DN $_request_dn, $_request_config| {
          $_request_base_dir = $_request_config['request_base_dir']
          $_request_base_filename = $_request_config['base_filename']
          ::dehydrated::certificate::collect{ "${_request_fqdn}-${_request_dn}" :
            request_dn            => $_request_dn,
            request_fqdn          => $_request_fqdn,
            request_base_dir      => $_request_base_dir,
            request_base_filename => $_request_base_filename,
          }
        }
      }
    }
  }


}
