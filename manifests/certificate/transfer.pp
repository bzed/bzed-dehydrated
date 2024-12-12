# Used as exported ressource to ransfer crt/ca files.
#
# @summary Transfer crt/ca files.
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
  Enum['crt', 'ca'] $file_type,
  Dehydrated::DN $request_dn,
  Stdlib::Fqdn $request_fqdn,
  String $request_base_filename,
  Variant[String, Binary] $file_content,
) {
  fail(
    'Do not instantiate this define, its only used to create exported ressources, collected from puppetdb'
  )
}
