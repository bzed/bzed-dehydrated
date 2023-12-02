# Used as exported ressource to ransfer crt/ca/ocsp files.
#
# @summary Transfer crt/ca/ocsp files.
#
# @example
#   dehydrated::certificate::transfer { 'namevar':
#       file_type    => 'crt',
#       request_dn   => 'domain.foo.bar.example.com',
#       request_fqdn => 'foo.bar.example.com',
#       file_content => '',
#   }
#
# @api private
#
define dehydrated::certificate::transfer (
  Enum['crt', 'ca', 'ocsp'] $file_type,
  Dehydrated::DN $request_dn,
  Stdlib::Fqdn $request_fqdn,
  Variant[String, Binary] $file_content,
) {
  if ! defined(Class['dehydrated']) {
    fail('You must include the dehydrated base class first.')
  }
  require dehydrated::setup

  $dehydrated_domains = $facts['dehydrated_domains']
  $_config = $dehydrated_domains[$request_dn]
  $base_filename = $_config['base_filename']

  $base_dir = $dehydrated::base_dir
  $csr_dir  = $dehydrated::csr_dir
  $key_dir  = $dehydrated::key_dir
  $crt_dir  = $dehydrated::crt_dir

  $crt = "${crt_dir}/${base_filename}.crt"
  $ca = "${crt_dir}/${base_filename}_ca.pem"
  $ocsp = "${crt}.ocsp"

  File {
    ensure => file,
    owner  => $dehydrated::user,
    group  => $dehydrated::group,
    mode   => '0644',
  }

  case $file_type {
    'crt' : {
      file { $crt :
        content => $file_content,
      }
    }
    'ca' : {
      file { $ca :
        content => $file_content,
      }
    }
    'ocsp' : {
      file { $ocsp :
        content => base64('decode', $file_content),
      }
    }
    default : {
      fail('unknown file type! this should never happen!')
    }
  }
}
