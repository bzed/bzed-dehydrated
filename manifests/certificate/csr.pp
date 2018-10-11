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
  Dehydrated::Algorithm $algorithm = 'rsa',
  #Optional[String] $country = undef,
  #Optional[String] $state = undef,
  #Optional[String] $locality = undef,
  #Optional[String] $organization = undef,
  #Optional[String] $unit = undef,
  #Optional[String] $email = undef,
  Optional[String] $key_password = undef,
  Enum['present', 'absent'] $ensure = 'present',
  Boolean $force = true,
  Optional[Integer[768]] $size = undef,
  Pattern[/^(MD[245]|SHA(|-?(1|224|256|384|512)))$/] $digest = 'SHA512',
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

  $crt = "${crt_dir}/${base_filename}.crt"
  $key = "${key_dir}/${base_filename}.key"
  $csr = "${csr_dir}/${base_filename}.csr"
  $dh  = "${crt_dir}/${base_filename}.dh"


  if ($ensure == 'present') {
    dehydrated_key { $key :
      algorithm => $algorithm,
      password  => $key_password,
      size      => $size,
      require   => File[$key_dir],
      before    => File[$key],
    }
    dehydrated_csr { $csr :
      private_key               => $key,
      password                  => $key_password,
      algorithm                 => $algorithm,
      subject_alternative_names => $subject_alternative_names,
      force                     => $force,
      digest                    => $digest,
      require                   => [
        File[$key],
      ]
    }
  }

  file { $key :
    ensure => $ensure,
    owner  => $::dehydrated::user,
    group  => $::dehydrated::group,
    mode   => '0640',
  }
  file { $csr :
    ensure  => $ensure,
    owner   => $::dehydrated::user,
    group   => $::dehydrated::group,
    mode    => '0644',
    require => X509_request[$csr],
  }


}
