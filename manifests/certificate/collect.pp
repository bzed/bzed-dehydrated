# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @example
#   dehydrated::certificate::collect { 'namevar': }
define dehydrated::certificate::collect(
  Dehydrated::DN $request_dn,
  Stdlib::Fqdn $request_fqdn,
  Stdlib::Absolutepath $request_base_dir,
  String $request_base_filename,
) {

  require ::dehydrated::setup::dehydrated_host
  require ::dehydrated::params

  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  if ($::dehydrated::params::dehydrated_puppetmaster == $facts['fqdn']) {
    # we are on a puppetmaster.
    # use file() to retrieve files.
    $dehydrated_requests_dir = $::dehydrated::dehydrated_requests_dir
    $crt_file = "${request_base_dir}/${request_base_filename}.crt"
    $ca_file = "${request_base_dir}/${request_base_filename}_ca.pem"
    $ocsp_file = "${crt_file}.ocsp"

    if find_file($crt) {
      $crt = file($crt_file)
    } else {
      $crt = undef
    }
    if find_file($ocsp_file) {
      $ocsp = binary_file($ocsp_file)
    } else {
      $ocsp = undef
    }
    if find_file($ca_file) {
      $ca = file($ca_file)
    } else {
      $ca = undef
    }

  } else {
    # we are on a non-puppetmaster host
    # use facter to retrieve files.
    if (
      has_key($facts, 'dehydrated_certificates') and
      has_key($facts['dehydrated_certificates'], $request_fqdn) and
      has_key($facts['dehydrated_certificates'][$request_fqdn], $request_dn)
    ) {
      $config = $facts['dehydrated_certificates'][$request_fqdn][$request_dn]
      if has_key($config, 'crt') {
        $crt = $config['crt']
      } else {
        $crt = undef
      }
      if (
        has_key($config, 'oscp') and
        $config['oscp'] =~ Stdlib::Base64
      ) {
        $oscp = Binary($config['oscp'])
      } else {
        $oscp = undef
      }
      if has_key($config, 'ca') {
        $ca = $config['ca']
      } else {
        $ca = undef
      }
    } else {
      notify { 'No dehydrated certificate config from facter :(' : }
      $crt = undef
      $oscp = undef
      $ca = undef
    }
  }

  if ($crt and $crt =~ Dehydrated::CRT) {
    @@dehydrated::certificate::transfer { "${name}-transfer-crt" :
      file_type    => 'crt',
      request_dn   => $request_dn,
      request_fqdn => $request_fqdn,
      file_content => $crt,
      tag          => [
        "request_fqdn:${request_fqdn}",
        "request_dn:${request_dn}"
      ],
    }
  }
  if ($ca and $ca =~ Dehydrated::CRT) {
    @@dehydrated::certificate::transfer { "${name}-transfer-ca" :
      file_type    => 'ca',
      request_dn   => $request_dn,
      request_fqdn => $request_fqdn,
      file_content => $ca,
      tag          => [
        "request_fqdn:${request_fqdn}",
        "request_dn:${request_dn}"
      ],
    }
  }
  if ($oscp) {
    @@dehydrated::certificate::transfer { "${name}-transfer-ocsp" :
      file_type    => 'ocsp',
      request_dn   => $request_dn,
      request_fqdn => $request_fqdn,
      file_content => $ocsp,
      tag          => [
        "request_fqdn:${request_fqdn}",
        "request_dn:${request_dn}"
      ],
    }
  }

}
