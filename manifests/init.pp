# Base class to setup the letsencrypt certificate handling
# with dehydrated.
#
# @summary Base class to define necessary variables and include setup classes.
#
# @example
#   # should be sufficient in most cases.
#   include dehydrated
#
#   # if you are "upgrading" from bzed-letsencrypt,
#   # you might want to use these options to stay
#   # compatible with the old group/directory:
#   class { 'dehydrated' :
#     group    => 'letsencrypt',
#     base_dir => '/etc/letsencrypt',
#   }
#
# @api public
# @param base_dir
#   The base directory where keys/csr/certs are stored.
#   Defaults to:
#   - on $::os['family']=='Debian': /etc/dehydrated 
#   - on other Linux/Unix systems: /etc/pki/dehydrated
#   - on windows: C:\LE_certs.
# @param crt_dir
#   The directory where certificates are stored. Defaults to ${base_dir}/certs
# @param csr_dir
#   The directory where CSRs are stored. Defaults to ${base_dir}/csr
# @param key_dir
#   The directory where pricate keys are stored. Defaults to ${base_dir}/private
# @param user
#   The user who owns the files in /etc/dehydrated.
# @param group
#   The group which owns the files in /etc/dehydrated. If you have a non-root process which
#   needs to access private keys, add its user to this group.
# @param dehydrated_user
#   User to run the dehydrated script as. Only used on the host that actually requests certificates.
# @param dehydrated_group
#   Group to run the dehydrated script as. Only used on the host that actually requests certificates.
# @param letsencrypt_ca
#   Let’s Encrypt CA to use. Defaults to v2-production. See the letsencrypt_cas parameter for a way
#   to specify your own Let’s Encrypt / ACME compatible CA. This configures the default CA to use, but
#   You can actually define different CAs for each certificate, see the ::dehydrated::certificate
#   define for details.
# @param letsencrypt_cas
#   Hash with the definitions of the official testing and production Let’s Encrypt CAs this
#   puppet module was tested against.
# @param dh_param_size
#   Default size of the DH params we should generate. Defaults to 2048.
# @param challengetype
#   Default challengetype to use. Defaults to 'dns-01'. You can specify a different
#   challengetype for each certificate, see ::dehydrated::certificate.
# @param algorithm
# @param dehydrated_base_dir
# @param dehydrated_git_dir
# @param dehydrated_git_tag
# @param dehydrated_git_url
# @param dehydrated_host
# @param dehydrated_requests_dir
# @param dehydrated_hooks_dir
# @param dehydrated_requests_config
# @param dehydrated_wellknown_dir
# @param dehydrated_alpncert_dir
# @param dehydrated_host_packages
# @param dehydrated_environment
# @param dehydrated_domain_validation_hook
# @param dehydrated_hook
# @param dehydrated_contact_email
# @param manage_user
#   Create $dehydrated_user/$dehydrated_group and $user/$group if necessary.
# @param manage_packages
#   Install required packages using ensure_packages?
#   Should be safe to leave enabled in most cases.
# @param pki_packages
#   Required packages to create /etc/pki. Not really used yet.
# @param packages
#   The list of packages we actually need to install to make this module work properly.
#   You are free to modify this list if you need to.
# @param certificates
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
  Dehydrated::Algorithm $algorithm = $::dehydrated::params::algorithm,

  Stdlib::Absolutepath $dehydrated_base_dir = $::dehydrated::params::dehydrated_base_dir,
  Stdlib::Absolutepath $dehydrated_git_dir = "${dehydrated_base_dir}/dehydrated",
  String $dehydrated_git_tag = $::dehydrated::params::dehydrated_git_tag,
  Dehydrated::GitUrl $dehydrated_git_url = $::dehydrated::params::dehydrated_git_url,
  Stdlib::Fqdn $dehydrated_host = $::dehydrated::params::dehydrated_host,
  Stdlib::Absolutepath $dehydrated_requests_dir = "${dehydrated_base_dir}/requests",
  Stdlib::Absolutepath $dehydrated_hooks_dir = "${dehydrated_base_dir}/hooks",
  Stdlib::Absolutepath $dehydrated_requests_config = "${dehydrated_base_dir}/requests.json",
  Stdlib::Absolutepath $dehydrated_wellknown_dir = "${dehydrated_base_dir}/acme-challenges",
  Stdlib::Absolutepath $dehydrated_alpncert_dir = "${dehydrated_base_dir}/alpn-certs",
  Stdlib::Absolutepath $dehydrated_status_file = "${dehydrated_base_dir}/status.json",
  Stdlib::Absolutepath $dehydrated_monitoring_status_file = "${dehydrated_base_dir}/monitoring.status",
  Array $dehydrated_host_packages = $::dehydrated::params::dehydrated_host_packages,
  Hash $dehydrated_environment = $::dehydrated::params::dehydrated_environment,
  Optional[Dehydrated::Hook] $dehydrated_domain_validation_hook = $::dehydrated::params::dehydrated_domain_validation_hook,
  Dehydrated::Hook $dehydrated_hook = "${challengetype}.sh",
  Optional[Dehydrated::Email] $dehydrated_contact_email = $::dehydrated::params::dehydrated_contact_email,

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

  $_fqdn_based_config = {
    'dehydrated_contact_email' => $dehydrated_contact_email,
  }

  $dehydrated_domains = $facts['dehydrated_domains']
  $dehydrated_domains.each |Dehydrated::DN $_dn, Hash $_config| {
    $_base_filename = $_config['base_filename']
    $_dh_param_size = $_config['dh_param_size']
    $_csr = $_config['csr']
    $_crt_serial = $_config['crt_serial']
    $_subject_alternative_names = $_config['subject_alternative_names']
    $_dehydrated_host = $_config['dehydrated_host']


    ::dehydrated::certificate::dh { $_base_filename :
      dn            => $_dn,
      dh_param_size => $_dh_param_size,
    }

    $request_name = join(
      concat(
        [$facts['fqdn'], $_dn],
        $_subject_alternative_names
      ),
    '-')

    $_request_config = merge($_fqdn_based_config, $_config)
    if $_csr =~ Dehydrated::CSR {
      @@dehydrated::certificate::request { $request_name :
        request_fqdn => $facts['fqdn'],
        config       => $_request_config,
        dn           => $_dn,
        tag          => "dehydrated-request-for-${_dehydrated_host}",
      }
    }

    Dehydrated::Certificate::Transfer<<|
      tag == "request_fqdn:${facts['fqdn']}" and
      tag == "request_dn:${_dn}"
    |>>

    if $_config['ready_for_merge'] {
      dehydrated::certificate::deploy { $_dn :
      }
    }

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
