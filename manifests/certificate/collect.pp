# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @example
#   dehydrated::certificate::collect { 'namevar':
#       request_dn            => '*.foo.bar.com',
#       request_fqdn          => 'foo.bar.com',
#       request_base_dir      => '/opt/dehydrated/requests',
#       request_base_filename => '_.foo.bar.com',
#   }
#
# @api private
#
define dehydrated::certificate::collect (
  Dehydrated::DN $request_dn,
  Stdlib::Fqdn $request_fqdn,
  Stdlib::Absolutepath $request_base_dir,
  String $request_base_filename,
) {
  require dehydrated::setup::dehydrated_host

  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  if ($dehydrated::dehydrated_puppetmaster == $facts['networking']['fqdn']) {
    # we are on a puppetmaster.
    # use file() to retrieve files.
    $dehydrated_requests_dir = $dehydrated::dehydrated_requests_dir
    $crt_file = "${request_base_dir}/${request_base_filename}.crt"
    $ca_file = "${request_base_dir}/${request_base_filename}_ca.pem"
    $ocsp_file = "${crt_file}.ocsp"

    $crt = dehydrated::file($crt_file)
    $ocsp = dehydrated::file($ocsp_file)
    $ca = dehydrated::file($ca_file)
  } else {
    # we are on a non-puppetmaster host
    # use facter to retrieve files.
    if (
      'dehydrated_certificates' in $facts and
      $request_fqdn in $facts['dehydrated_certificates'] and
      $request_dn in $facts['dehydrated_certificates'][$request_fqdn]
    ) {
      $config = $facts['dehydrated_certificates'][$request_fqdn][$request_dn]
      if 'crt' in $config {
        $crt = $config['crt']
      } else {
        $crt = undef
      }
      if (
        'ocsp' in $config and
        $config['ocsp'] =~ Stdlib::Base64
      ) {
        $ocsp = String(Binary($config['ocsp']))
      } else {
        $ocsp = undef
      }
      if 'ca' in $config {
        $ca = $config['ca']
      } else {
        $ca = undef
      }
    } else {
      notify { 'No dehydrated certificate config from facter :(' : }
      $crt = undef
      $ocsp = undef
      $ca = undef
    }
  }

  if ($crt and $crt =~ Dehydrated::CRT) {
    @@dehydrated::certificate::transfer { "${name}-transfer-crt" :
      file_type             => 'crt',
      request_dn            => $request_dn,
      request_fqdn          => $request_fqdn,
      file_content          => $crt,
      request_base_filename => $request_base_filename,
    }
  }
  if ($ca and $ca =~ Dehydrated::CRT) {
    @@dehydrated::certificate::transfer { "${name}-transfer-ca" :
      file_type             => 'ca',
      request_dn            => $request_dn,
      request_fqdn          => $request_fqdn,
      file_content          => $ca,
      request_base_filename => $request_base_filename,
    }
  }
  if ($ocsp) {
    @@dehydrated::certificate::transfer { "${name}-transfer-ocsp" :
      file_type             => 'ocsp',
      request_dn            => $request_dn,
      request_fqdn          => $request_fqdn,
      file_content          => $ocsp,
      request_base_filename => $request_base_filename,
    }
  }
}
