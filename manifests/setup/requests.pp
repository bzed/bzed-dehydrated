# @summary Deploy requests.json file on dehydrated host
#
# We collect all request information from puppetdb, clean, enrich and merge it
# to create requests.json on the dehydrated host
#
# @example
#   include dehydrated::setup::requests
class dehydrated::setup::requests {
  assert_private()

  include dehydrated::params

  $request_query = @("EOF":json)
    ["from", "resources",
      [ "extract",
        [
          "title",
          "certname",
          "parameters.request_fqdn",
          "parameters.dn",
          "parameters.config"
        ],
        [
          "and",
          [ "=", "type", "Dehydrated::Certificate::Request" ],
          [ "=", "parameters.dehydrated_host", "${trusted['certname']}" ],
          [ "=", "exported", true ]
        ]
      ]
    ]
    | EOF

  $request_data = puppetdb_query($request_query)
  $request_config_list = $request_data.map |$_request| {
    $request_fqdn = $_request['parameters.request_fqdn']
    $dn = $_request['parameters.dn']
    $config = $_request['parameters.config']

    $base_filename = $config['base_filename']
    $dh_param_size = $config['dh_param_size']
    $crt_serial = $config['crt_serial']
    $fingerprints = $config['fingerprints']
    $subject_alternative_names = $config['subject_alternative_names']
    $dehydrated_host = $config['dehydrated_host']
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
    $dehydrated_config = [$request_base_dir, "${base_filename}.config"].join($dehydrated::params::path_seperator)

    $letsencrypt_ca_url = $dehydrated::letsencrypt_cas[$letsencrypt_ca]['url']
    $letsencrypt_ca_hash = $dehydrated::letsencrypt_cas[$letsencrypt_ca]['hash']

    $csr = $config['csr']
    $csr_file = [$request_base_dir, "${base_filename}.csr"].join($dehydrated::params::path_seperator)

    $request_config = {
      $request_fqdn => {
        $dn           => {
          'subject_alternative_names'                => $subject_alternative_names,
          'base_filename'                            => $base_filename,
          'crt_serial'                               => $crt_serial,
          'fingerprints'                             => $fingerprints,
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
          'dehydrated_config_content'                => template('dehydrated/dehydrated/config.erb'),
          'csr_file'                                 => $csr_file,
          'csr_content'                              => $csr,
        },
      },
    }
    $request_config
  }

  $requests = $request_config_list.reduce({}) |$memo, $c| {
    deep_merge($memo, $c)
  }

  file { $dehydrated::dehydrated_requests_config :
    ensure    => file,
    owner     => $dehydrated::dehydrated_user,
    group     => $dehydrated::dehydrated_group,
    mode      => '0640',
    require   => [
      User[$dehydrated::dehydrated_user],
      Group[$dehydrated::dehydrated_group],
    ],
    content   => stdlib::to_json_pretty($requests),
    show_diff => false,
  }
}
