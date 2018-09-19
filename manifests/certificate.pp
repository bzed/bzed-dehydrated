# Triggers key and csr generation and installs the
# certificate 
#
# @summary Creates key & csr and deploys the certificate.
#
# @example
#   dehydrated::certificate { 'test.example.com': }
define dehydrated::certificate(
  Dehydrated::DN $dn = $name,
  Array[Dehydrated::DN] $subject_alternative_names = [],
  Dehydrated::Challengetype $challengetype = $::dehydrated::challengetype,
  Integer $dh_param_size = $::dehydrated::dh_param_size,
  Stdlib::Fqdn $dehydrated_host = $::dehydrated::dehydrated_host,
) {

  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  require ::dehydrated::setup


}
