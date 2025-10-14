# Deploy collected certificate and CA files.
#
# @summary Deploy collected certificate and CA files.
#
# @param ensure
# present/absent
# absent removes all related files!
#
# @param dn
# Certificate DN
#
# @param key_password
# Password of the key if needed to access it.
#
# @example
#   dehydrated::certificate::deploy { 'namevar': }
#
# @api private
#
define dehydrated::certificate::deploy (
  Enum['present', 'absent'] $ensure = 'present',
  Dehydrated::DN $dn = $name,
  Optional[String] $key_password = undef,
) {
  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }

  include dehydrated
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

  if ($ensure == 'present') {
    Concat {
      owner => $dehydrated::user,
      group => $dehydrated::group,
    }

    concat { $crt_full_chain :
      mode => '0644',
    }
    concat { $crt_full_chain_with_key :
      mode => '0640',
    }

    concat::fragment { "${dn}_key" :
      target  => $crt_full_chain_with_key,
      source  => $key,
      order   => '01',
      require => Dehydrated_key[$key],
    }
    concat::fragment { "${dn}_key_linebreak" :
      target  => $crt_full_chain_with_key,
      content => "\n\n",
      order   => '02',
      require => Dehydrated_key[$key],
    }
    concat::fragment { "${dn}_fullchain" :
      target    => $crt_full_chain_with_key,
      source    => $crt_full_chain,
      order     => '10',
      subscribe => Concat[$crt_full_chain],
    }

    concat::fragment { "${dn}_crt" :
      target  => $crt_full_chain,
      source  => $crt,
      order   => '10',
      require => File[$crt],
    }
    concat::fragment { "${dn}_crt_linebreak" :
      target  => $crt_full_chain,
      content => "\n\n",
      order   => '11',
      require => File[$crt],
    }

    concat::fragment { "${dn}_dh" :
      target  => $crt_full_chain,
      source  => $dh,
      order   => '30',
      require => File[$dh],
    }
    concat::fragment { "${dn}_dh_linebreak" :
      target  => $crt_full_chain,
      content => "\n",
      order   => '31',
      require => File[$dh],
    }

    concat::fragment { "${dn}_ca" :
      target  => $crt_full_chain,
      source  => $ca,
      order   => '50',
      require => File[$ca],
    }

    if ($dehydrated::build_pfx_files) {
      $dehydrated_pfx_ensure = 'present'
      dehydrated_pfx { $pfx:
        ensure        => 'present',
        pkcs12_name   => $dn,
        key_password  => $key_password,
        password      => $key_password,
        ca            => $ca,
        certificate   => $crt,
        private_key   => $key,
        mac_algorithm => $dehydrated::pkcs12_mac_algorithm,
        certpbe       => $dehydrated::pkcs12_certpbe,
        keypbe        => $dehydrated::pkcs12_keypbe,
        require       => [
          File[$crt],
          File[$ca],
          File[$key],
          Dehydrated_key[$key],
        ],
        subscribe     => Concat[$crt_full_chain_with_key],
      }
    } else {
      file { $pfx:
        ensure => absent,
      }
    }
  } else {
    $cert_files = [
      $cnf,
      $crt,
      $key,
      $pfx,
      $csr,
      $dh ,
      $ca,

      $crt_full_chain,
      $crt_full_chain_with_key,
    ]
    file { $cert_files:
      ensure => absent,
    }
  }
}
