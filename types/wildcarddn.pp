# based on Stdlib::Fqdn
# lint:ignore:140chars
type Dehydrated::WildcardDN = Pattern[/^\*\.(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/]
# lint:endignore
