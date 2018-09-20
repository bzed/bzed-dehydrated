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
  Integer[768] $dh_param_size = $::dehydrated::dh_param_size,
  Stdlib::Fqdn $dehydrated_host = $::dehydrated::dehydrated_host,
  Optional[String] $key_password = undef,
) {

  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  require ::dehydrated::setup
  require ::dehydrated::params

  $base_filename = regsubst($dn, '^\*', '_wildcard_')

  $domain_config = {
    $dn => {
      subject_alternative_names => $subject_alternative_names,
      base_filename             => $base_filename,
      dh_param_size             => $dh_param_size,
      challengetype             => $challengetype,
    }
  }

  $json_fragment = to_json($domain_config)
  concat::fragment { "${fqdn}-${dn}" :
    target  => $::dehydrated::params::domainfile,
    content => $json_fragment,
    order   => '50'
  }

  ::dehydrated::certificate::csr { $base_filename :
    dn                        => $dn,
    subject_alternative_names => $subject_alternative_names,
    key_password              => $key_password,
  }



}
