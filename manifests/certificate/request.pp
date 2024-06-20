# Does all the necessary things to be able to request a certificate
# from letsencrypt using the csr created and shipped to the
# dehydrated_host.
#
# @summary Prepare everything to request a certifificate for our CSRs.
#
# @example
#   dehydrated::certificate::request { 'namevar':
#       request_fqdn    => 'foo.bar.example.com',
#       dn              => 'domain.bar.example.com',
#       config          => {},
#       dehydrated_host => host.that.runs.dehydrated,
#   }
#
# @api private
#
define dehydrated::certificate::request (
  Stdlib::Fqdn $request_fqdn,
  Dehydrated::DN $dn,
  Hash $config,
  Stdlib::Fqdn $dehydrated_host,
) {
  fail(
    'Do not instantiate this define, its only used to create exported ressources, collected from puppetdb'
  )
}
