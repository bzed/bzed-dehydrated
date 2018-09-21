# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @example
#   dehydrated::certificate::request { 'namevar': }
#
# @api private
#
define dehydrated::certificate::request(
  Stdlib::Fqdn $request_fqdn,
  Dehydrated::DN $dn,
  Array[Dehydrated::DN] $subject_alternative_names,
  String $base_filename,
  Dehydrated::CSR $csr,
  Integer $crt_serial,
) {

  require ::dehydrated::params

  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  $dehydrated_base_dir = $::dehydrated::dehydrated_base_dir

  $request_fqdn_dir = join(
    [$dehydrated_base_dir, $request_fqdn],
    $::dehydrated::params::path_seperator
  )
  $request_base_dir = join(
    [$request_fqdn_dir, $base_filename],
    $::dehydrated::params::path_seperator
  )

  $csr_file = join(
    [$request_base_dir, "${base_filename}.csr"],
    $::dehydrated::params::path_seperator
  )

  File {
    owner => $::dehydrated::dehydrated_user,
    group => $::dehydrated::dehydrated_group,
  }

  ensure_resource(
    'file',
    $request_fqdn_dir,
    {
      'ensure' => 'directory',
      'owner'  => $::dehydrated::dehydrated_user,
      'group'  => $::dehydrated::dehydrated_group,
      'mode'   => '0755',
    }
  )

  ensure_resource(
    'file',
    $request_base_dir,
    {
      'ensure' => 'directory',
      'owner'  => $::dehydrated::dehydrated_user,
      'group'  => $::dehydrated::dehydrated_group,
      'mode'   => '0755',
    }
  )

  file { $csr_file :
    ensure  => file,
    content => $csr,
  }

  $request_config = {
    $request_fqdn =>  {
      $dn           => {
        'subject_alternative_names' => $subject_alternative_names,
        'base_filename'             => $base_filename,
        'crt_serial'                => $crt_serial,
        'request_fqdn_dir'          => $request_fqdn_dir,
        'request_base_dir'          => $request_base_dir,
      }
    }
  }

  $json_fragment = to_json($request_config)
  ::concat::fragment { $name :
    target  => $::dehydrated::dehydrated_requests_config,
    content => $json_fragment,
    order   => '50',
  }

}
