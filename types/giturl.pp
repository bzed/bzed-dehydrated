# a type that hopefully matches all possible git urls.
type Dehydrated::GitUrl = Variant[Dehydrated::GitSSHUrl, Stdlib::HTTPUrl, Stdlib::Absolutepath]
