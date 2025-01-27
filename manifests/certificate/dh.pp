# Create dh params files as necessary.
#
# @summary Create the DH params file.
#
# @example
#   dehydrated::certificate::dh { 'test.example.com':
#     dh_param_size => 1024,
#     base_filename => 'test.example.com',
#   }
#
# @api private
#
define dehydrated::certificate::dh (
  Dehydrated::DN $dn,
  Integer[786] $dh_param_size,
  String $base_filename = $name,
  Enum['present', 'absent'] $ensure = 'present',
  Integer[3600] $max_age = (30*24*60*60),
) {
  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  require dehydrated::setup

  $crt_dir  = $dehydrated::crt_dir
  $dh  = "${crt_dir}/${base_filename}.dh"

  dehydrated_dhparam { $dh :
    size   => $dh_param_size,
  }

  file { $dh:
    ensure  => $ensure,
    owner   => $dehydrated::user,
    group   => $dehydrated::group,
    mode    => '0644',
    require => Dehydrated_dhparam[$dh],
  }
}
