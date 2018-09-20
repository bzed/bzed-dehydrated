# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @example
#   dehydrated::certificate::dh { 'test.example.com':
#     dh_param_size => 1024,
#     base_filename => 'test.example.com',
#   }
#
# @api private
#
define dehydrated::certificate::dh(
  Dehydrated::DN $dn,
  Integer[786] $dh_param_size,
  Integer $current_dh_mtime,
  String $base_filename = $name,
  Enum['present', 'absent'] $ensure = 'present',
  Integer[3600] $max_age = (30*24*60*60),
) {
  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  require ::dehydrated::setup

  $crt_dir  = $::dehydrated::crt_dir
  $dh  = "${crt_dir}/${base_filename}.dh"

  $old_mtime = $facts['dehydrated_dh_mtimes'][$dn]

  if (($old_mtime + $max_age) <= time() and ($ensure == 'present')) {
    exec { "create-dh-for-${dn}-${base_filename}" :
      path    => $facts['path'],
      user    => $::dehydrated::user,
      group   => $::dehydrated::group,
      umask   => '022',
      command => "openssl dhparam -check -out ${dh} ${dh_param_size}",
      require => File[$crt_dir],
      before  => File[$dh],
    }
  }

  file { $dh:
    ensure => $ensure,
    owner  => $::dehydrated::user,
    group  => $::dehydrated::group,
    mode   => '0644',
  }

}
