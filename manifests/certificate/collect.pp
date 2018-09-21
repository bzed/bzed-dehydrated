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

    $crt = file_or_nil($crt_file)
    $ocsp = file_or_nil($ocsp_file)
    $ca = file_or_nil($ocsp_file)
  } else {
    # we are on a random host
    # use facter to retrieve files.
    $crt = ''
    $ocsp = ''
    $ca = ''
  }

}
