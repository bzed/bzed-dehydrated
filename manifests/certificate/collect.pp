# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @param request_dn
# DN of the request we want to collect
#
# @param request_fqdn
# FQDN of the requesting host
#
# @param request_base_dir
# Base directory for lesencrypt certificates/keys
#
# @param request_base_filename
# Base filename of the certificate/request/key
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
  require dehydrated::params

  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  if ($dehydrated::params::dehydrated_puppetmaster == $trusted['certname']) {
    # we are on a puppetmaster.
    # use file() to retrieve files.
    $dehydrated_requests_dir = $dehydrated::dehydrated_requests_dir
    $crt_file = "${request_base_dir}/${request_base_filename}.crt"
    $ca_file = "${request_base_dir}/${request_base_filename}_ca.pem"

    $crt = dehydrated::file($crt_file)
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
      if 'ca' in $config {
        $ca = $config['ca']
      } else {
        $ca = undef
      }
    } else {
      notify { 'No dehydrated certificate config from facter :(' : }
      $crt = undef
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
}
