# Manage certificate keys and create CSRs for the
# configured domains / altnames.
#
# @summary Creates a key file with CSR
#
# @param dn
# Certificate DN
#
# @param subject_alternative_names
# Array of SANs
#
# @param base_filename
# base filename, used for csr/key filename by default
#
# @param csr_filename
# filename for the csr file
#
# @param key_filename
# filename for the key file
#
# @param algorithm
# algorithm to use, defaults to rsa
#
# @param country
# country to write into the csr, not used by letsencrypt
#
# @param state
# state to write into the csr, not used by letsencrypt
#
# @param locality
# locality to write into the csr, not used by letsencrypt
#
# @param organization
# organization to write into the csr, not used by letsencrypt
#
# @param organizational_unit
# organizational_unit to write into the csr, not used by letsencrypt
#
# @param email_address
# email address to write into the csr, not used by letsencrypt
#
# @param key_password
# Set / use key password to access/write the key
#
# @param ensure
# Ensure absent/present
#
# @param force
# Overwrite csr if it exists and doesn't match
#
# @param size
# Optional size param
#
# @param digest
# Digest to use, defaults to SHA512
#
# @example
#   dehydrated::csr { '_wildcard_.example.com':
#     $subject_alternative_names => [],
#     $dn                        => '*.example.com'
#   }
#
# @api private
#
define dehydrated::certificate::csr (
  Dehydrated::DN $dn,
  Array[Dehydrated::DN] $subject_alternative_names,
  String $base_filename = $name,
  String $csr_filename = "${name}.csr",
  String $key_filename = "${name}.key",
  Dehydrated::Algorithm $algorithm = 'rsa',
  Optional[String] $country = undef,
  Optional[String] $state = undef,
  Optional[String] $locality = undef,
  Optional[String] $organization = undef,
  Optional[String] $organizational_unit = undef,
  Optional[String] $email_address = undef,
  Optional[String] $key_password = undef,
  Enum['present', 'absent'] $ensure = 'present',
  Boolean $force = true,
  Optional[Integer[768]] $size = undef,
  Pattern[/^(MD[245]|SHA(|-?(1|224|256|384|512)))$/] $digest = 'SHA512',
) {
  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  require dehydrated::setup

  $base_dir = $dehydrated::base_dir
  $csr_dir  = $dehydrated::csr_dir
  $key_dir  = $dehydrated::key_dir
  $crt_dir  = $dehydrated::crt_dir

  $crt = "${crt_dir}/${base_filename}.crt"
  $key = "${key_dir}/${base_filename}.key"
  $csr = "${csr_dir}/${base_filename}.csr"
  $dh  = "${crt_dir}/${base_filename}.dh"
  $fingerprint = "${key}.fingerprint"

  if ($ensure == 'present') {
    dehydrated_key { $key :
      ensure    => $ensure,
      algorithm => $algorithm,
      password  => $key_password,
      size      => $size,
      require   => File[$key_dir],
      before    => File[$key],
    }
    dehydrated_fingerprint { $fingerprint :
      ensure      => $ensure,
      private_key => $key,
      password    => $key_password,
      require     => Dehydrated_key[$key],
    }
    dehydrated_csr { $csr :
      ensure                    => $ensure,
      private_key               => $key,
      password                  => $key_password,
      algorithm                 => $algorithm,
      common_name               => $dn,
      subject_alternative_names => $subject_alternative_names,
      country                   => $country,
      state                     => $state,
      locality                  => $locality,
      organization              => $organization,
      organizational_unit       => $organizational_unit,
      email_address             => $email_address,
      force                     => $force,
      digest                    => $digest,
      require                   => [
        File[$key],
        File[$csr_dir],
        Dehydrated_key[$key],
      ],
      before                    => File[$csr],
    }
  }

  file { $key :
    ensure => $ensure,
    owner  => $dehydrated::user,
    group  => $dehydrated::group,
    mode   => '0640',
  }
  file { $csr :
    ensure  => $ensure,
    owner   => $dehydrated::user,
    group   => $dehydrated::group,
    mode    => '0644',
    require => Dehydrated_csr[$csr],
  }
}
