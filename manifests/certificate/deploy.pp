# Deploy collected certificate and CA files.
#
# @summary Deploy collected certificate and CA files.
#
# @example
#   dehydrated::certificate::deploy { 'namevar': }
#
# @api private
#
define dehydrated::certificate::deploy (
  Dehydrated::DN $dn = $name,
  Optional[String] $key_password = undef,
) {
  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  require dehydrated::setup

  $dehydrated_domains = $facts['dehydrated_domains']
  $_config = $dehydrated_domains[$dn]
  $base_filename = $_config['base_filename']

  $base_dir = $dehydrated::base_dir
  $csr_dir  = $dehydrated::csr_dir
  $key_dir  = $dehydrated::key_dir
  $crt_dir  = $dehydrated::crt_dir

  $cnf = "${base_dir}/${base_filename}.cnf"
  $crt = "${crt_dir}/${base_filename}.crt"
  $key = "${key_dir}/${base_filename}.key"
  $pfx = "${key_dir}/${base_filename}.pfx"
  $csr = "${csr_dir}/${base_filename}.csr"
  $dh  = "${crt_dir}/${base_filename}.dh"
  $ca = "${crt_dir}/${base_filename}_ca.pem"

  $crt_full_chain = "${crt_dir}/${base_filename}_fullchain.pem"
  $crt_full_chain_with_key = "${key_dir}/${base_filename}_fullchain_with_key.pem"

  Concat {
    owner => $dehydrated::user,
    group => $dehydrated::group,
  }

  concat { $crt_full_chain :
    mode => '0644',
  }
  concat { $crt_full_chain_with_key :
    mode   => '0640',
    notify => Dehydrated_pfx[$pfx],
  }

  concat::fragment { "${dn}_key" :
    target => $crt_full_chain_with_key,
    source => $key,
    order  => '01',
  }
  concat::fragment { "${dn}_fullchain" :
    target    => $crt_full_chain_with_key,
    source    => $crt_full_chain,
    order     => '10',
    subscribe => Concat[$crt_full_chain],
  }

  concat::fragment { "${dn}_crt" :
    target => $crt_full_chain,
    source => $crt,
    order  => '10',
  }
  concat::fragment { "${dn}_dh" :
    target => $crt_full_chain,
    source => $dh,
    order  => '30',
  }

  concat::fragment { "${dn}_ca" :
    target => $crt_full_chain,
    source => $ca,
    order  => '50',
  }

  if ($dehydrated::build_pfx_files) {
    $dehydrated_pfx_ensure = 'present'
  } else {
    $dehydrated_pfx_ensure = 'absent'
  }
  dehydrated_pfx { $pfx:
    ensure       => $dehydrated_pfx_ensure,
    pkcs12_name  => $dn,
    key_password => $key_password,
    password     => $key_password,
    ca           => $ca,
    certificate  => $crt,
    private_key  => $key,
  }
}
