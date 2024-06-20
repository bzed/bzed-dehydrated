# Does all the necessary things to be able to request a certificate
# from letsencrypt using the csr created and shipped to the
# dehydrated_host.
#
# @summary Prepare everything to request a certifificate for our CSRs.
#
# @example
#   dehydrated::certificate::request { 'namevar':
#       request_fqdn => 'foo.bar.example.com',
#       dn           => 'domain.bar.example.com',
#       config       => {},
#   }
#
# @api private
#
define dehydrated::certificate::request (
  Stdlib::Fqdn $request_fqdn,
  Dehydrated::DN $dn,
  Hash $config,
  Optional[String] $dehydrated_host = undef,
) {
  require dehydrated::params

  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  $base_filename = $config['base_filename']
  $dh_param_size = $config['dh_param_size']
  $csr = $config['csr']
  $crt_serial = $config['crt_serial']
  $subject_alternative_names = $config['subject_alternative_names']
  $dehydrated_environment = $config['dehydrated_environment']
  $dehydrated_hook = $config['dehydrated_hook']
  $dehydrated_hook_script = if $dehydrated_hook and $dehydrated_hook != '' {
    [$dehydrated::dehydrated_hooks_dir, $dehydrated_hook].join($dehydrated::params::path_seperator)
  }

  $dehydrated_domain_validation_hook = $config['dehydrated_domain_validation_hook']
  $dehydrated_domain_validation_hook_script = if $dehydrated_domain_validation_hook and $dehydrated_domain_validation_hook != '' {
    [$dehydrated::dehydrated_hooks_dir, $dehydrated_domain_validation_hook].join($dehydrated::params::path_seperator)
  }

  $letsencrypt_ca = $config['letsencrypt_ca']
  $dehydrated_contact_email = pick_default($config['dehydrated_contact_email'], '')

  $challengetype = $config['challengetype']

  # added later, handle missing config
  $_preferred_chain = $config.dig('preferred_chain')
  $preferred_chain = if !empty($_preferred_chain) { $_preferred_chain }

  $dehydrated_requests_dir = $dehydrated::dehydrated_requests_dir

  $request_fqdn_dir = [$dehydrated_requests_dir, $request_fqdn].join($dehydrated::params::path_seperator)
  $request_base_dir = [$request_fqdn_dir, $base_filename].join($dehydrated::params::path_seperator)
  $request_account_dir = if $dehydrated::accounts_per_agent {
    [$request_fqdn_dir, 'accounts'].join($dehydrated::params::path_seperator)
  } else {
    [$dehydrated::dehydrated_base_dir, 'accounts'].join($dehydrated::params::path_seperator)
  }
  $csr_file = [$request_base_dir, "${base_filename}.csr"].join($dehydrated::params::path_seperator)
  $dehydrated_config = [$request_base_dir, "${base_filename}.config"].join($dehydrated::params::path_seperator)

  $letsencrypt_ca_url = $dehydrated::letsencrypt_cas[$letsencrypt_ca]['url']
  $letsencrypt_ca_hash = $dehydrated::letsencrypt_cas[$letsencrypt_ca]['hash']

  $dehydrated_wellknown_dir = $dehydrated::dehydrated_wellknown_dir
  $dehydrated_alpncert_dir = $dehydrated::dehydrated_alpncert_dir

  File {
    owner => $dehydrated::dehydrated_user,
    group => $dehydrated::dehydrated_group,
  }

  ensure_resource(
    'file',
    $request_fqdn_dir,
    {
      'ensure' => 'directory',
      'owner'  => $dehydrated::dehydrated_user,
      'group'  => $dehydrated::dehydrated_group,
      'mode'   => '0755',
    }
  )

  ensure_resource(
    'file',
    $request_base_dir,
    {
      'ensure' => 'directory',
      'owner'  => $dehydrated::dehydrated_user,
      'group'  => $dehydrated::dehydrated_group,
      'mode'   => '0755',
    }
  )

  file { $csr_file :
    ensure  => file,
    content => $csr,
  }

  file { $dehydrated_config :
    ensure  => file,
    content => template('dehydrated/dehydrated/config.erb'),
  }

  $request_config = {
    $request_fqdn => {
      $dn           => {
        'subject_alternative_names'                => $subject_alternative_names,
        'base_filename'                            => $base_filename,
        'crt_serial'                               => $crt_serial,
        'request_fqdn_dir'                         => $request_fqdn_dir,
        'request_base_dir'                         => $request_base_dir,
        'request_account_dir'                      => $request_account_dir,
        'dehydrated_environment'                   => $dehydrated_environment,
        'dehydrated_hook_script'                   => $dehydrated_hook_script,
        'dehydrated_domain_validation_hook_script' => $dehydrated_domain_validation_hook_script,
        'dehydrated_contact_email'                 => $dehydrated_contact_email,
        'letsencrypt_ca_url'                       => $letsencrypt_ca_url,
        'letsencrypt_ca_hash'                      => $letsencrypt_ca_hash,
        'dehydrated_config'                        => $dehydrated_config,
      },
    },
  }

  $json_fragment = to_json($request_config)
  ::concat::fragment { "${facts['dehydrated::dehydrated_requests_config']}-${name}" :
    target  => $dehydrated::dehydrated_requests_config,
    content => $json_fragment,
    order   => '50',
  }
}
