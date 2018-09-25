# Manage certificate keys and create CSRs for the
# configured domains / altnames.
#
# @summary Creates a key file with CSR
#
# @example
#   dehydrated::csr { '_wildcard_.example.com':
#     $subject_alternative_names => [],
#     $dn                        => '*.example.com'
#   }
#
# @api private
define dehydrated::certificate::csr(
  Dehydrated::DN $dn,
  Array[Dehydrated::DN] $subject_alternative_names,
  String $base_filename = $name,
  String $csr_filename = "${name}.csr",
  String $key_filename = "${name}.key",
  Optional[String] $country = undef,
  Optional[String] $state = undef,
  Optional[String] $locality = undef,
  Optional[String] $organization = undef,
  Optional[String] $unit = undef,
  Optional[String] $email = undef,
  Optional[String] $key_password = undef,
  Enum['present', 'absent'] $ensure = 'present',
  Boolean $force = true,
) {

  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  require ::dehydrated::setup

  $base_dir = $::dehydrated::base_dir
  $csr_dir  = $::dehydrated::csr_dir
  $key_dir  = $::dehydrated::key_dir
  $crt_dir  = $::dehydrated::crt_dir

  if (!empty($subject_alternative_names)) {
    $req_ext = true
  } else {
    $req_ext = false
  }

  $cnf = "${base_dir}/${base_filename}.cnf"
  $crt = "${crt_dir}/${base_filename}.crt"
  $key = "${key_dir}/${base_filename}.key"
  $csr = "${csr_dir}/${base_filename}.csr"
  $dh  = "${crt_dir}/${base_filename}.dh"


  file { $cnf :
    ensure  => $ensure,
    owner   => $::dehydrated::user,
    group   => $::dehydrated::group,
    mode    => '0644',
    content => template('dehydrated/certificate/cert.cnf.erb'),
  }

  if ($ensure == 'present') {
    ssl_pkey { $key :
      ensure   => $ensure,
      password => $key_password,
      require  => File[$key_dir],
    }
    x509_request { $csr :
      ensure      => $ensure,
      template    => $cnf,
      private_key => $key,
      password    => $key_password,
      force       => $force,
      require     => File[$cnf],
    }
  }

  file { $key :
    ensure  => $ensure,
    owner   => $::dehydrated::user,
    group   => $::dehydrated::group,
    mode    => '0640',
    require => Ssl_pkey[$key],
  }
  file { $csr :
    ensure  => $ensure,
    owner   => $::dehydrated::user,
    group   => $::dehydrated::group,
    mode    => '0644',
    require => X509_request[$csr],
  }


}
