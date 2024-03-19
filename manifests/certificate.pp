# Triggers key and csr generation and requests the certificate
# via the host configured in $dehydrated_host.
# This is the main defined type to use if you want to have a
# certificate. Together with the defaults in the dehydrated
# class you should have everything to make requesting certificates
# possible. Especially the dehydrated::certificate::* types do not
# have a public API and can change without warning. Don't rely on
# them.
# Dehydrated::Certificate[$dn] is also what you want to use to
# subscribe to if you want to restart services after certificates
# have been installed/updated.
#
# @summary Creates key & csr and request the certificate.
#
# @example
#   dehydrated::certificate { 'test.example.com': }
#
# @api public
#
# @param dn
#   The main distinguished name to use for the certificate.
#   Defaults to $name.
#
# @param base_filename
#   The base part of the filename of all related files.
#   For wildcard certificates the * is replaced by _wildcard_.
#   Feel free to use whatever a valid filename is.
# @param subject_alternative_names
#   To request a SAN certificate, pass an array with the
#   alternative names here. The main $dn will be added automatically.
# @param challengetype
#   Default challengetype to use. Defaults to $dehydrated::challengetype,
#   which defaults to 'dns-01'. You can specify a different
#   challengetype for each certificate here.
# @param algorithm
#   Algorithm / elliptic-curve you want to use. Supported: rsa, secp384r1, prime256v1.
#   Defaults to $dehydrated::algorithm, which defaults to 'rsa'.
#   You can specify a different algorithm for each certificate here.
# @param dh_param_size
#   Size of the DH params we should generate. Defaults to $dehydrated::dh_param_size,
#   which defaults to 2048. You can specify a different DH param size for each certificate here.
# @param dehydrated_host
#   $::fqdn of the host which is responsible to request the certificates from
#   the Let's Encrypt CA. Defaults to $dehydrated::dehydrated_host where you can
#   configure your default.
# @param dehydrated_environment
#   Hash with the environment variables to set for the $dehydrated_domain_validation_hook
#   and also for running the hook in dehydrated.
#   Defaults to $dehydrated::dehydrated_environment, empty by default.
# @param dehydrated_hook
#   Name of the hook script you want to use. Can be left on undef if http-01 is being
#   used as challengetype to use the built-in http-01 implementation of dehydrated.
#   Defaults to $dehydrated::dehydrated_hook, which will use "${challengetype}.sh"
#   if the challengetype is not http-01.
# @param letsencrypt_ca
#   Defines the CA you want to use to request certificates. If you want to use a
#   non-supported CA, you need to configure it in $dehydrated::letsencrypt_cas on
#   your $dehydrated_host.
#   Normally, the following CAs are pre-configured:
#   staging, production, v2-staging, v2-production
#   Defaults to $dehydrated::letsencrypt_ca, which points to v2-production.
# @param dehydrated_domain_validation_hook
#   Name of the hook script to run before dehydrated is actually executed.
#   Used to check if a domain is still valid or if you are allowed to modify it.
#   Or whatever else you want to do as preparation.
#   Good thing to use before running into limits by trying to request
#   certificates for domains you don't own.
#   Defaults to $dehydrated::dehydrated_domain_validation_hook where you
#   can configure the default for your setup.
# @param key_password
#   If your key should be protected by a password, specify it here.
define dehydrated::certificate (
  Dehydrated::DN $dn = $name,
  String $base_filename = regsubst($dn, '^\*', '_wildcard_'),
  Array[Dehydrated::DN] $subject_alternative_names = [],
  Dehydrated::Challengetype $challengetype = $dehydrated::challengetype,
  Dehydrated::Algorithm $algorithm = $dehydrated::algorithm,
  Integer[768] $dh_param_size = $dehydrated::dh_param_size,
  Stdlib::Fqdn $dehydrated_host = $dehydrated::dehydrated_host,
  Hash $dehydrated_environment = $dehydrated::dehydrated_environment,
  Optional[Dehydrated::Hook] $dehydrated_hook = $dehydrated::dehydrated_hook,
  String $letsencrypt_ca = $dehydrated::letsencrypt_ca,
  Optional[Dehydrated::Hook] $dehydrated_domain_validation_hook = $dehydrated::dehydrated_domain_validation_hook,
  Optional[String] $key_password = undef,
  Optional[String] $preferred_chain = $dehydrated::preferred_chain,
) {
  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  require dehydrated::setup
  require dehydrated::params

  # ensure $dn is also in subject_alternative_names
  $_subject_alternative_names = unique(flatten([$dn, $subject_alternative_names]))

  $domain_config = {
    $dn => {
      'subject_alternative_names'         => $_subject_alternative_names,
      'base_filename'                     => $base_filename,
      'dh_param_size'                     => $dh_param_size,
      'challengetype'                     => $challengetype,
      'dehydrated_host'                   => $dehydrated_host,
      'dehydrated_environment'            => $dehydrated_environment,
      'dehydrated_hook'                   => $dehydrated_hook,
      'dehydrated_domain_validation_hook' => $dehydrated_domain_validation_hook,
      'letsencrypt_ca'                    => $letsencrypt_ca,
      'preferred_chain'                   => $preferred_chain,
    },
  }

  $json_fragment = to_json($domain_config)
  ::concat::fragment { "${facts['networking']['fqdn']}-${dn}" :
    target  => $dehydrated::params::domainfile,
    content => $json_fragment,
    order   => '50',
  }

  dehydrated::certificate::csr { $base_filename :
    dn                        => $dn,
    subject_alternative_names => $subject_alternative_names,
    key_password              => $key_password,
    algorithm                 => $algorithm,
  }

  $ready_for_merge = pick(
    $facts.dig('dehydrated_domains', $dn, 'ready_for_merge'),
    false
  )
  if $ready_for_merge {
    dehydrated::certificate::deploy { $dn :
      key_password => $key_password,
    }
  }
}
