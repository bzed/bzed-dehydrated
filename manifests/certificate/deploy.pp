# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @example
#   dehydrated::certificate::deploy { 'namevar': }
define dehydrated::certificate::deploy(
  Dehydrated::DN $dn = $name,
) {

  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  require ::dehydrated::setup

  $dehydrated_domains = $facts['dehydrated_domains']
  $_config = $dehydrated_domains[$dn]
  $base_filename = $_config['base_filename']

  $base_dir = $::dehydrated::base_dir
  $csr_dir  = $::dehydrated::csr_dir
  $key_dir  = $::dehydrated::key_dir
  $crt_dir  = $::dehydrated::crt_dir

  $cnf = "${base_dir}/${base_filename}.cnf"
  $crt = "${crt_dir}/${base_filename}.crt"
  $key = "${key_dir}/${base_filename}.key"
  $csr = "${csr_dir}/${base_filename}.csr"
  $dh  = "${crt_dir}/${base_filename}.dh"
  $ca = "${crt_dir}/${base_filename}_ca.pem"

  $crt_full_chain = "${crt_dir}/${base_filename}_fullchain.pem"
  $crt_full_chain_with_key = "${key_dir}/${base_filename}_fullchain_with_key.pem"

  Concat {
    owner => $::dehydrated::user,
    group => $::dehydrated::group,
  }

  concat { $crt_full_chain :
    mode => '0644',
  }
  concat { $crt_full_chain_with_key :
    mode => '0644',
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

}
